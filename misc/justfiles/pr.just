[doc('Create a new Pull Request')]
create:
    @echo "🚀 Creating Pull Request..."
    gh pr create --fill

[doc('Ask Gemini to review the Pull Request')]
review n="":
    gh pr comment {{ n }} --body "/gemini review"

[doc('View comments for the Pull Request')]
view n="":
    #!/usr/bin/env bash
    set -euo pipefail
    # set -x

    OUT_DIR=${BUILD_DIR}/pr
    OWNER="$(gh repo view --json owner --jq '.owner.login')"
    REPO="$(gh repo view --json name --jq '.name')"
    PR="{{ n }}"

    if [ -z "$PR" ]; then
        PR="$(gh pr view --json number --jq '.number')"
    fi

    mkdir -p ${OUT_DIR}
    gh pr view {{ n }} --comments >> "${OUT_DIR}/pr-${PR}-comments.md"

    gh api graphql \
      -F owner="$OWNER" \
      -F repo="$REPO" \
      -F pr="$PR" \
      -f query='query($owner: String!, $repo: String!, $pr: Int!) { repository(owner: $owner, name: $repo) { pullRequest(number: $pr) { reviewThreads(first: 100) { nodes { isResolved comments(first: 100) { nodes { author { login } body path line createdAt } } } } } } }' \
      >> "${OUT_DIR}/pr-${PR}-comments.json"

    echo "✅ Saved PR info"
