#!/bin/bash
# Check if a filename is provided as an argument
if [ -z "$1" ]; then
    echo "Please provide a filename as an argument."
    exit 1
fi

# Check if the input file exists
if [ ! -f "$1" ]; then
    echo "File not found: $1"
    exit 1
fi

# Define the input file
INFILE="$1"
FILENAME=$(basename "$1" .txt)

# Start the XML file with the header
cat << EOF > local_manifest.xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
EOF

# Initialize associative arrays to store remotes, projects, and remove-projects
declare -A REMOTES
declare -A TREES
declare -A PROJECTS
declare -A REMOVE_PROJECTS

# Read the input file line by line
while IFS= read -r LINE || [ -n "$LINE" ]; do
    # Remove carriage return and leading/trailing whitespace
    LINE=$(echo "$LINE" | tr -d '\r' | xargs)
    
    # Check if the line starts with curly braces
    if [[ $LINE =~ ^\{.*\}$ ]]; then
        # Extract TESTING_URL and TESTING_BRANCH
        read -r TESTING_URL TESTING_BRANCH <<< $(echo "$LINE" | tr -d '{}' | tr '"' ' ')
        continue
    fi
    
    # Check if the line starts with "add"
    if [[ $LINE == add* ]]; then
        # Extract the repository URL, local path, and branch from the line
        read -r _ REPO_URL LOCAL_PATH BRANCH <<< $(echo "$LINE" | tr '"' ' ')

        # Extract the repository name and owner from the URL
        REPO_NAME=$(basename "$REPO_URL" .git)
        REPO_OWNER=$(basename "$(dirname "$REPO_URL")")

        # Extract the domain name from the URL
        DOMAIN_NAME=$(echo "$REPO_URL" | sed -E 's/https?:\/\/([^\/]+).*/\1/')

        # Add remote to the REMOTES array if not already present
        if [[ ! " ${!REMOTES[@]} " =~ " ${REPO_OWNER} " ]]; then
            REMOTES[$REPO_OWNER]="    <remote name=\"$REPO_OWNER\" fetch=\"https://$DOMAIN_NAME/$REPO_OWNER\" clone-depth=\"1\" />"
        fi

        # Add project to the PROJECTS array
        PROJECT_KEY="${LOCAL_PATH}|${REPO_NAME}"
        PROJECTS[$PROJECT_KEY]="    <project path=\"$LOCAL_PATH\" name=\"$REPO_NAME\" remote=\"$REPO_OWNER\" revision=\"$BRANCH\" />"
    fi
    
        # Check if the line starts with "tree"
    if [[ $LINE == tree* ]]; then
        # Extract the repository URL, local path, and branch from the line
        read -r _ REPO_URL LOCAL_PATH BRANCH <<< $(echo "$LINE" | tr '"' ' ')

        # Extract the repository name and owner from the URL
        REPO_NAME=$(basename "$REPO_URL" .git)
        REPO_OWNER=$(basename "$(dirname "$REPO_URL")")

        # Extract the domain name from the URL
        DOMAIN_NAME=$(echo "$REPO_URL" | sed -E 's/https?:\/\/([^\/]+).*/\1/')

        # Add remote to the REMOTES array if not already present
        if [[ ! " ${!REMOTES[@]} " =~ " ${REPO_OWNER} " ]]; then
            REMOTES[$REPO_OWNER]="    <remote name=\"$REPO_OWNER\" fetch=\"https://$DOMAIN_NAME/$REPO_OWNER\" clone-depth=\"1\" />"
        fi

        # Add project to the TREES array
        TREE_KEY="${LOCAL_PATH}|${REPO_NAME}"
        TREES[$TREE_KEY]="    <project path=\"$LOCAL_PATH\" name=\"$REPO_NAME\" remote=\"$REPO_OWNER\" revision=\"$BRANCH\" />"
    fi
    
    # Check if the line starts with "remove"
    if [[ $LINE == remove* ]]; then
        # Extract the path to remove
        PATH_TO_REMOVE=$(echo "$LINE" | awk '{print $2}' | tr -d '"')
        
        # Clone the manifest repository if it doesn't exist
        if [ ! -d "manifest" ]; then
            git clone "$TESTING_URL" -b "$TESTING_BRANCH" manifest
        fi
        
        # Find the matching line in the manifest
        MATCH=$(grep -r "path=\"$PATH_TO_REMOVE\"" manifest)
        
        if [ -n "$MATCH" ]; then
            # Extract the full name from the matched line
            FULL_NAME=$(echo "$MATCH" | sed -n 's/.*name="\([^"]*\)".*/\1/p')
            
            # Add a removal entry to the REMOVE_PROJECTS array
            REMOVE_PROJECTS[$FULL_NAME]="    <remove-project name=\"$FULL_NAME\" />"
        fi
    fi
done < "$INFILE"

# Clean up
rm -rf manifest

echo "" >> local_manifest.xml

echo "Writting remotes..."
# Output remotes
echo "    <!-- Remotes -->" >> local_manifest.xml
for remote in "${REMOTES[@]}"; do
    echo "$remote" >> local_manifest.xml
done
echo "" >> local_manifest.xml

echo "Writting trees..."
# Output tree-projects
echo "    <!-- Trees -->" >> local_manifest.xml
for tree in "${TREES[@]}"; do
    echo "$tree" >> local_manifest.xml
done
echo "" >> local_manifest.xml

echo "Removing projects..."
# Output remove-project entries
echo "    <!-- Removals -->" >> local_manifest.xml
for remove_project in "${REMOVE_PROJECTS[@]}"; do
    echo "$remove_project" >> local_manifest.xml
done
echo "" >> local_manifest.xml

echo "Writting projects..."
# Output projects
echo "    <!-- Repos -->" >> local_manifest.xml
for project in "${PROJECTS[@]}"; do
    echo "$project" >> local_manifest.xml
done
echo "" >> local_manifest.xml

# Close the XML file
echo '</manifest>' >> local_manifest.xml
echo "Local manifest generated as local_manifest.xml"
