import json
import requests
from collections import OrderedDict

# fetch version: -> https://downloads.mongodb.org/full.json
# prefer use local version file
def update_all_version_from_api():
    url = "https://downloads.mongodb.org/full.json"
    response = requests.get(url)
    data = response.json()
    if response.status_code != 200:
        print("Failed to fetch data from api")
        return

    with open("mongo_versions.json", 'w', encoding="utf-8") as file:
        json.dump(data, file, indent=4)

def get_all_version():
    linux_version_set = OrderedDict()
    macos_version_set = OrderedDict()
    windows_version_set = OrderedDict()
    with open("mongo_versions.json", 'r', encoding="utf-8") as file:
        data = json.load(file)
        for item in data.get("versions", []):
            basic_version = item.get("version")

            if basic_version is None:
                continue

            for download in item.get("downloads", []):
                arch = download.get('arch')
                edition = download.get('edition')
                target = download.get('target')

                if arch is None or edition is None or target is None:
                    continue

                if target == "windows":
                    version = f"{target}-{arch}-{edition}-{basic_version}"
                    if edition == "base" or edition == "targeted":
                        version = f"{target}-{arch}-{basic_version}"
                    windows_version_set[version] = None
                elif target == "macos" or target == "osx-ssl" or target == "osx":
                    version = f"{target}-{arch}-{edition}-{basic_version}"
                    if edition == "base" or edition == "targeted":
                        version = f"{target}-{arch}-{basic_version}"
                    macos_version_set[version] = None
                else:
                    version = f"{arch}-{edition}-{target}-{basic_version}"
                    if edition == "base" or edition == "targeted":
                        version = f"{arch}-{target}-{basic_version}"
                    linux_version_set[version] = None                
    return list(linux_version_set.keys()), list(macos_version_set.keys()), list(windows_version_set.keys())

if __name__ == "__main__":
    update_all_version_from_api()
    linux_version_set, macos_version_set, windows_version_set = get_all_version()
    with open("linux_versions.txt", 'w') as file:
        for version in linux_version_set:
            file.write(version + '\n')

    with open("darwin_versions.txt", 'w') as file:
        for version in macos_version_set:
            file.write(version + '\n')

    with open("windows_versions.txt", 'w') as file:
        for version in windows_version_set:
            file.write(version + '\n')