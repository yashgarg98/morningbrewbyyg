#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  Morning Brew by YG — GitHub Pages one-shot deploy script
#  Run this once from the morningbrewbyYG folder.
#
#  Requirements:
#    • git  (https://git-scm.com)
#    • curl (pre-installed on macOS/Linux; use Git Bash on Windows)
#    • A GitHub Personal Access Token with repo scope
#      → github.com/settings/tokens → New token → check "repo"
# ─────────────────────────────────────────────────────────────

set -e

# ── Prompt for credentials ───────────────────────────────────
read -p "GitHub username : " GH_USER
read -sp "GitHub token    : " GH_TOKEN
echo ""

REPO_NAME="morningbrewbyyg"
API="https://api.github.com"

# ── Validate token first ─────────────────────────────────────
echo ""
echo "→ Validating token..."
AUTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "$API/user")

if [ "$AUTH_CHECK" != "200" ]; then
  echo "✗ Token invalid or missing 'repo' scope (HTTP $AUTH_CHECK)."
  echo "  Generate one at: https://github.com/settings/tokens"
  echo "  Choose 'Classic token' and check the 'repo' checkbox."
  exit 1
fi
echo "✓ Token valid."

echo "→ Creating repository '$REPO_NAME'..."

RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "$API/user/repos" \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"$REPO_NAME\",
    \"description\": \"Morning Brew by YG — daily world & India news digest\",
    \"homepage\": \"https://$GH_USER.github.io/$REPO_NAME\",
    \"private\": false,
    \"auto_init\": false
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -1)

if [ "$HTTP_CODE" == "201" ]; then
  echo "✓ Repository created."
elif [ "$HTTP_CODE" == "422" ]; then
  echo "! Repository already exists — pushing to existing repo."
else
  echo "✗ Error creating repo (HTTP $HTTP_CODE):"
  echo "$BODY"
  exit 1
fi

REMOTE="https://$GH_USER:$GH_TOKEN@github.com/$GH_USER/$REPO_NAME.git"

# ── Init git & push ──────────────────────────────────────────
echo "→ Initialising git and pushing files..."
git init -b main
git add .
git commit -m "Initial deploy: Morning Brew by YG"
git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE"
git push -u origin main --force

# ── Enable GitHub Pages ──────────────────────────────────────
echo "→ Enabling GitHub Pages..."
curl -s -X POST "$API/repos/$GH_USER/$REPO_NAME/pages" \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "Content-Type: application/json" \
  -d '{"source":{"branch":"main","path":"/"}}' > /dev/null

echo ""
echo "────────────────────────────────────────────────────────"
echo "✅  All done!"
echo ""
echo "   Your site will be live in ~60 seconds at:"
echo "   https://$GH_USER.github.io/$REPO_NAME"
echo ""
echo "   GitHub repo:"
echo "   https://github.com/$GH_USER/$REPO_NAME"
echo "────────────────────────────────────────────────────────"