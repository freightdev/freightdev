#!/bin/zsh

DIR=${1:-.}
OUTPUT="$DIR/PROJECT_CONTEXT.md"

echo "=== PROJECT CONTEXT ===" > $OUTPUT
echo "Path: $(realpath $DIR)" >> $OUTPUT
echo "Created: $(date)" >> $OUTPUT
echo >> $OUTPUT

echo "=== FILE STATS ===" >> $OUTPUT
find $DIR -type f | wc -l | awk '{print "Total Files: "$1}' >> $OUTPUT
find $DIR -type f -name "*.go" | wc -l | awk '{print "Go Files: "$1}' >> $OUTPUT
find $DIR -type f -name "*.js" | wc -l | awk '{print "JS Files: "$1}' >> $OUTPUT
find $DIR -type f -name "*.ts" | wc -l | awk '{print "TS Files: "$1}' >> $OUTPUT
find $DIR -type f -name "*.py" | wc -l | awk '{print "Python Files: "$1}' >> $OUTPUT
find $DIR -type f -name "*.java" | wc -l | awk '{print "Java Files: "$1}' >> $OUTPUT
find $DIR -type f -name "*.md" | wc -l | awk '{print "Markdown Files: "$1}' >> $OUTPUT
echo >> $OUTPUT

echo "=== DIRECTORY STRUCTURE ===" >> $OUTPUT
tree -L 3 $DIR >> $OUTPUT 2>/dev/null || find $DIR -maxdepth 3 -print >> $OUTPUT
echo >> $OUTPUT

echo "=== TOP LEVEL FILES ===" >> $OUTPUT
ls -1 $DIR >> $OUTPUT
echo >> $OUTPUT

echo "=== RECENT CHANGES ===" >> $OUTPUT
if git -C $DIR rev-parse --git-dir > /dev/null 2>&1; then
  git -C $DIR log --oneline -10 >> $OUTPUT
else
  echo "No git history available" >> $OUTPUT
fi
echo >> $OUTPUT

echo "=== FILE SIZES (TOP 10) ===" >> $OUTPUT
find $DIR -type f -printf "%s %p\n" 2>/dev/null | sort -nr | head -10 | awk '{print $2" ("$1" bytes)"}' >> $OUTPUT
