## Generate Manifest 
Generate your first local_manifest from a list of repos using Github Action.

### [Original Repo](https://github.com/sounddrill31/actions_generate_local_manifests)
## How to use
* Fork this repository
* Add `PAT` Secret with `Personal Access Token` in settings
* Create your [device file](#device-file)
* Go to Actions tab
* Click on "Test Manifest/Generate Manifest" on left-hand-side menu
* Choose branch `gen`
* Run the workflow.
* Output will be committed to your `local_manifest` repo replacing the file `local_manifest.xml` with new branch as per name of your text file.

### Notes
* This does not handle conflicts with ROM manifests, as it just generates a simple template. Fix them manually using remove-project.
* Feed it to an XML checker to ensure things are a-ok, fix it if they are not.
* Put Vendor and other heavy repos last

### Device File:
* Create a txt file for your device by name of rom/device {Filename will be used as branch name}
* Add testing ROM
```
{ "https://github.com/ROM/manifest" "branch_name" }
```
* Add Projects with `add` & device trees with `tree`
```
add "https://github.com/username/repo_number_1.git" "path/to/clone" "branch_name"
```
* Remove projects with `remove`
```
remove "path/to/folder"
```
### Example:
```
{ "https://github.com/LineageOS/android" "lineage-21.0" }
tree "https://github.com/rahulkhatri137/android_device_oppo_CPH1859" "device/oppo/CPH1859" "twelve"
add "https://github.com/rahulkhatri137/device_mediatek_sepolicy_vndr" "device/mediatek/sepolicy_vndr" "twelve"
remove "frameworks/base"
```
