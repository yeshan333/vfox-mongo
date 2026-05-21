import os
import re
import requests


def fetch_all_releases():
    """Paginate GitHub releases API for mongodb-js/mongosh."""
    headers = {"Accept": "application/vnd.github+json"}
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"

    releases = []
    for page in range(1, 21):
        url = f"https://api.github.com/repos/mongodb-js/mongosh/releases?per_page=100&page={page}"
        resp = requests.get(url, headers=headers)
        if resp.status_code != 200:
            print(f"GitHub API returned {resp.status_code} on page {page}, stopping.")
            break
        data = resp.json()
        if not data:
            break
        releases.extend(data)
    return releases


def extract_stable_versions(releases):
    """Filter to stable releases and return sorted semver list (newest first)."""
    semver_re = re.compile(r"^\d+\.\d+\.\d+$")
    versions = []
    for rel in releases:
        if rel.get("prerelease") or rel.get("draft"):
            continue
        tag = rel.get("tag_name", "")
        version = tag.lstrip("v")
        if not semver_re.match(version):
            continue
        parts = tuple(int(x) for x in version.split("."))
        versions.append((parts, version))

    versions.sort(key=lambda x: x[0], reverse=True)
    return [v for _, v in versions]


if __name__ == "__main__":
    releases = fetch_all_releases()
    versions = extract_stable_versions(releases)
    print(f"Found {len(versions)} stable mongosh versions")

    with open("mongosh_versions.txt", "w") as f:
        for v in versions:
            f.write(v + "\n")

    if versions:
        print(f"Latest: {versions[0]}, oldest: {versions[-1]}")
