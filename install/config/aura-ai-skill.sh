
# Place in ~/.claude/skills since all tools populate from there as well as their own sources


mkdir -p ~/.claude/skills


ln -s $AURA_PATH/default/aura-skill ~/.claude/skills/aura
ln -s $AURA_PATH/default/ambxst-skill ~/.claude/skills/ambxst
