# markdownlint style file for davewiki2

# MD029 - Ordered list item prefix
# Allow either '1.' for all items OR incrementing numbers (both are valid markdown)
rule 'MD029', :style => :one_or_ordered

# MD007 - Unordered list indentation
# Use 2-space indentation for lists
rule 'MD007', :indent => 2

# Exclude these rules
exclude_rule 'MD013'  # Line length - many lines are intentionally long (commands, code, URLs)
exclude_rule 'MD033'  # Inline HTML - sometimes needed for special formatting
exclude_rule 'MD041'  # First line should be top level header - not applicable for AGENTS.md
exclude_rule 'MD024'  # Multiple headers with same content - common in long documents
exclude_rule 'MD034'  # Bare URL used - URLs render fine in most markdown parsers