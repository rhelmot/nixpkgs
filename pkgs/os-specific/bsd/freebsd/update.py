#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p git "python3.withPackages (ps: with ps; [ gitpython packaging beautifulsoup4 pandas lxml ])"

import bs4
import git
import io
import itertools
import json
import os
import packaging.version
import pandas
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import typing
import urllib.request

BASE_DIR = pathlib.Path(__file__).parent.resolve()
MIN_VERSION = packaging.version.Version("13.0.0")

MAIN_BRANCH = "main"
REMOTE = "origin"

QUERY_VERSION_PATTERN = re.compile('^([A-Z]+)="(.+)"$')
TAG_PATTERN = re.compile(
    f"^release/({packaging.version.VERSION_PATTERN})$", re.IGNORECASE | re.VERBOSE
)
BRANCH_PATTERN = re.compile(
    f"^{REMOTE}/((stable|releng)/({packaging.version.VERSION_PATTERN}))$",
    re.IGNORECASE | re.VERBOSE,
)


def hash_dir(path: pathlib.PurePath | str):
    return (
        subprocess.check_output(
            [
                "nix",
                "--extra-experimental-features",
                "nix-command",
                "hash",
                "path",
                "--sri",
                path,
            ]
        )
        .decode("utf-8")
        .strip()
    )


# Ersatz ca-derivations
# FreeBSD vendors everything, meaning a small security update
# to openssh that we don't even use changes the source derivation,
# and therefore requires a mass rebuild.
# However, if we make all of the `filterSource` results fixed-output
# and don't include any version-specific info
# (i.e. sys/conf/newvers.sh and its outputs)
# then only things that have changed sources have to be rebuilt.
#
# If we could use the ca-derivations unstable feature then we'd have
# nothing to do in Python.
def eval_package_paths():
    # Pass options as json in an environment variable in case something isn't shell safe
    options = {"nixpkgsDir": str(BASE_DIR.parents[3])}
    env = os.environb | {b"UPDATE_OPTIONS": json.dumps(options).encode("utf-8")}
    proc = subprocess.run(
        [
            "nix",
            "--extra-experimental-features",
            "nix-command",
            "eval",
            "--impure",
            "--json",
            "--show-trace",
            "--file",
            str(BASE_DIR / "pathEval.nix"),
        ],
        env=env,
        check=True,
        stdout=subprocess.PIPE,
    )
    return json.loads(proc.stdout)


def hash_partial_commit(
    temp_path: pathlib.Path,
    work_dir: pathlib.Path,
    ref_name: str,
    pname: str,
    paths: typing.List[str],
):
    print(f"{ref_name}: {pname}: copying files")
    filtered_dir = temp_path / "filtered"
    filtered_hash = None
    os.mkdir(filtered_dir)
    try:
        for path in paths:
            src = work_dir / path
            dest = filtered_dir / path

            # shutil is fussy about existing files
            if dest.exists() and dest.is_dir():
                shutil.rmtree(dest)
            elif dest.exists():
                dest.unlink()

            if src.is_dir():
                shutil.copytree(src, dest, symlinks=True, dirs_exist_ok=True)
            else:
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dest, follow_symlinks=False)

        filtered_hash = hash_dir(filtered_dir)
        print(f"{ref_name}: {pname}: hash is {filtered_hash}")

    except FileNotFoundError as e:
        print(
            f"{ref_name}: {package_obj['pname']}: WARNING: file {e.filename} does not exist, skipping"
        )

    shutil.rmtree(filtered_dir)

    return filtered_hash


def request_supported_refs() -> typing.List[str]:
    # Looks pretty shady but I think this should work with every version of the page in the last 20 years
    r = re.compile("^h\d$", re.IGNORECASE)
    soup = bs4.BeautifulSoup(
        urllib.request.urlopen("https://www.freebsd.org/security"), features="lxml"
    )
    header = soup.find(
        lambda tag: r.match(tag.name) is not None
        and tag.text.lower() == "supported freebsd releases"
    )
    table = header.find_next("table")
    df = pandas.read_html(io.StringIO(table.prettify()))[0]
    return list(df["Branch"])


def query_version(repo: git.Repo):
    # This only works on FreeBSD 13 and later
    text = (
        subprocess.check_output(
            ["bash", os.path.join(repo.working_dir, "sys", "conf", "newvers.sh"), "-v"]
        )
        .decode("utf-8")
        .strip()
    )
    fields = dict()
    for line in text.splitlines():
        m = QUERY_VERSION_PATTERN.match(line)
        if m is None:
            continue
        fields[m[1].lower()] = m[2]

    fields["major"] = packaging.version.parse(fields["revision"]).major
    return fields


def handle_commit(
    repo: git.Repo,
    rev: git.objects.commit.Commit,
    ref_name: str,
    ref_type: str,
    supported_refs: typing.List[str],
):
    repo.git.checkout(rev)
    print(f"{ref_name}: checked out {rev.hexsha}")

    full_hash = hash_dir(repo.working_dir)
    print(f"{ref_name}: hash is {full_hash}")

    version = query_version(repo)
    print(f"{ref_name}: version is {version['version']}")

    return {
        "rev": rev.hexsha,
        "hash": full_hash,
        "ref": ref_name,
        "refType": ref_type,
        "supported": ref_name in supported_refs,
        "version": query_version(repo),
    }


# Normally uses /run/user/*, which is on a tmpfs and too small
temp_dir = tempfile.TemporaryDirectory(dir="/tmp")
temp_path = pathlib.Path(temp_dir.name)
print(f"Selected temporary directory {temp_path}")

if len(sys.argv) >= 2:
    orig_repo = git.Repo(sys.argv[1])
    print(f"Fetching updates on {orig_repo.git_dir}")
    orig_repo.remote("origin").fetch()
else:
    print("Cloning source repo")
    orig_repo = git.Repo.clone_from(
        "https://git.FreeBSD.org/src.git", to_path=temp_path / "orig"
    )

supported_refs = request_supported_refs()
print(f"Supported refs are: {' '.join(supported_refs)}")

print("Doing git crimes, do not run `git worktree prune` until after script finishes!")
work_dir = temp_path / "work"
git.cmd.Git(orig_repo.git_dir).worktree("add", "--orphan", work_dir)

# Have to create object before removing .git otherwise it will complain
repo = git.Repo(work_dir)
repo.git.set_persistent_git_options(git_dir=repo.git_dir)
# Remove so that nix hash doesn't see the file
os.remove(work_dir / ".git")

print(f"Working in directory {repo.working_dir} with git directory {repo.git_dir}")

versions = dict()
for tag in repo.tags:
    m = TAG_PATTERN.match(tag.name)
    if m is None:
        continue
    version = packaging.version.parse(m[1])
    if version < MIN_VERSION:
        print(f"Skipping old tag {tag.name} ({version})")
        continue

    print(f"Trying tag {tag.name} ({version})")

    result = handle_commit(repo, tag.commit, tag.name, "tag", supported_refs)
    versions[tag.name] = result

for branch in repo.remote("origin").refs:
    m = BRANCH_PATTERN.match(branch.name)
    if m is not None:
        fullname = m[1]
        version = packaging.version.parse(m[3])
        if version < MIN_VERSION:
            print(f"Skipping old branch {fullname} ({version})")
            continue
        print(f"Trying branch {fullname} ({version})")
    elif branch.name == f"{REMOTE}/{MAIN_BRANCH}":
        fullname = MAIN_BRANCH
        print(f"Trying development branch {fullname}")
    else:
        continue

    result = handle_commit(repo, branch.commit, fullname, "branch", supported_refs)
    versions[fullname] = result

# Write versions.json for the first time so we can get the right extraPaths
with open(BASE_DIR / "versions.json", "w") as out:
    json.dump(versions, out, sort_keys=True)

all_package_paths = eval_package_paths()

for ref_name in versions.keys():
    rev = versions[ref_name]["rev"]
    repo.git.checkout(versions[ref_name]["rev"])
    print(f"{ref_name}: checked out {rev}")

    versions[ref_name]["filteredHashes"] = dict()
    package_paths = all_package_paths[ref_name]
    for main_path, package_obj in package_paths.items():
        filtered_hash = hash_partial_commit(
            temp_path,
            work_dir,
            ref_name,
            package_obj["pname"],
            package_obj["paths"],
        )
        if filtered_hash is not None:
            versions[ref_name]["filteredHashes"][main_path] = package_obj | {
                "hash": filtered_hash
            }


# Write versions.json for the second time with all the data
with open(BASE_DIR / "versions.json", "w") as out:
    json.dump(versions, out, sort_keys=True)
