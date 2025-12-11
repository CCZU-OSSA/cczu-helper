# Reference from https://github.com/venera-app/venera/blob/master/update_alt_store.py
import json
import re
import requests
from datetime import datetime
import os


def prepare_description(text):
    text = re.sub("<[^<]+?>", "", text)  # Remove HTML tags
    text = re.sub(r"#{1,6}\s?", "", text)  # Remove markdown header tags
    text = re.sub(
        r"\*{2}", "", text
    )  # Remove all occurrences of two consecutive asterisks
    text = re.sub(
        r"(?<=\r|\n)-", "•", text
    )  # Only replace - with • if it is preceded by \r or \n
    text = re.sub(r"`", '"', text)  # Replace ` with "
    text = re.sub(
        r"\r\n\r\n", "\r \n", text
    )  # Replace \r\n\r\n with \r \n (avoid incorrect display of the description regarding paragraphs)
    return text


def fetch_latest_release(repo_url):
    api_url = f"https://api.github.com/repos/{repo_url}/releases"
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "cczu-helper-updater/1.0",
    }
    token = os.getenv('GITHUB_TOKEN')
    if token:
        headers["Authorization"] = f"Bearer {token}"
    try:
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        release = response.json()
        return release
    except requests.RequestException as e:
        print(f"Error fetching releases: {e}")
        raise


def get_file_size(url):
    try:
        response = requests.head(url)
        response.raise_for_status()
        return int(response.headers.get("Content-Length", 0))
    except requests.RequestException as e:
        print(f"Error getting file size: {e}")
        return 194586


def update_json_file_release(json_file, latest_release):
    if isinstance(latest_release, list) and latest_release:
        latest_release = latest_release[0]
    else:
        print("Error getting latest release")
        return

    try:
        with open(json_file, "r") as file:
            data = json.load(file)
    except json.JSONDecodeError as e:
        print(f"Error reading JSON file: {e}")
        data = {"apps": []}
        raise

    if not data["apps"]:
        # Initialize the app if apps array is empty
        initial_app = {
            "beta": False,
            "name": "CCZU Helper",
            "bundleIdentifier": "io.github.cczuossa.cczu_helper",
            "developerName": "CCZU-OSSA",
            "subtitle": "A app for making you living better in CCZU",
            "localizedDescription": "A app for making you living better in CCZU",
            "iconURL": "https://raw.githubusercontent.com/CCZU-OSSA/cczu-helper/master/assets/cczu_helper_icon.png",
            "tintColor": "#FD3C6FFF",
            "category": "utilities",
            "appPermissions": {
                "entitlements": [
                    "application-identifier",
                    "com.apple.security.application-groups",
                    "get-task-allow",
                    "keychain-access-groups"
                ],
                "privacy": {
                    "NSPhotoLibraryUsageDescription": "需要访问您的相册以选择图片",
                    "NSDocumentsFolderUsageDescription": "需要访问您的文件以保存和读取数据",
                    "NSFileProviderDomainUsageDescription": "需要访问文件以进行操作"
                }
            },
            "versions": []
        }
        data["apps"].append(initial_app)

    app = data["apps"][0]

    full_version = latest_release["tag_name"]
    tag = latest_release["tag_name"]
    # Extract version like 1.4.5 from tag, which may be like 'v1.4.5'
    version_match = re.search(r"(\d+\.\d+\.\d+)", full_version)
    if version_match:
        version = version_match.group(1)
    else:
        print("Error: Could not parse version from tag_name.")
        return
    version_date = latest_release["published_at"]
    date_obj = datetime.strptime(version_date, "%Y-%m-%dT%H:%M:%SZ")
    version_date = date_obj.strftime("%Y-%m-%d")

    description = latest_release["body"]
    description = prepare_description(description)

    assets = latest_release.get("assets", [])
    download_url = None
    size = None
    for asset in assets:
        if asset["name"] == "cczu-helper-ios.ipa":
            download_url = asset["browser_download_url"]
            size = asset["size"]
            break

    if download_url is None or size is None:
        print("Error: IPA file not found in release assets.")
        return

    version_entry = {
        "version": version,
        "date": version_date,
        "localizedDescription": description,
        "downloadURL": download_url,
        "size": size,
    }

    duplicate_entries = [item for item in app["versions"] if item["version"] == version]
    if duplicate_entries:
        app["versions"].remove(duplicate_entries[0])

    app["versions"].insert(0, version_entry)

    app.update(
        {
            "version": version,
            "versionDate": version_date,
            "versionDescription": description,
            "downloadURL": download_url,
            "size": size,
        }
    )

    if "news" not in data:
        data["news"] = []

    news_identifier = f"release-{full_version}"
    date_string = date_obj.strftime("%d/%m/%y")
    news_entry = {
        "appID": "io.github.cczuossa.cczu_helper",
        "caption": "Update of CCZU Helper just got released!",
        "date": latest_release["published_at"],
        "identifier": news_identifier,
        "notify": True,
        "tintColor": "#0784FC",
        "title": f"{full_version} - CCZU Helper  {date_string}",
        "url": f"https://github.com/CCZU-OSSA/cczu-helper/releases/tag/{tag}",
    }

    news_entry_exists = any(
        item["identifier"] == news_identifier for item in data["news"]
    )
    if not news_entry_exists:
        data["news"].append(news_entry)

    try:
        with open(json_file, "w") as file:
            json.dump(data, file, indent=2)
        print("JSON file updated successfully.")
    except IOError as e:
        print(f"Error writing to JSON file: {e}")
        raise


def main():
    repo_url = "CCZU-OSSA/cczu-helper"

    try:
        fetched_data_latest = fetch_latest_release(repo_url)
        json_file = "alt_store.json"
        update_json_file_release(json_file, fetched_data_latest)
    except Exception as e:
        print(f"An error occurred: {e}")
        raise


if __name__ == "__main__":
    main()
