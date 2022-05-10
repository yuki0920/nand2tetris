targets=("projects/10/ArrayTest/" "projects/10/ExpressionLessSquare/" "projects/10/Square/")
for target in "${targets[@]}"
do
  echo "Compile $target"
  ruby projects/10/jack_analyzer/jack_analyzer.rb $target
done

tests=(
  "projects/10/ArrayTest/MainT"
  "projects/10/ExpressionLessSquare/MainT"
  "projects/10/ExpressionLessSquare/SquareT"
  "projects/10/ExpressionLessSquare/SquareGameT"
  "projects/10/Square/MainT"
  "projects/10/Square/SquareT"
  "projects/10/Square/SquareGameT"
)

for test in "${tests[@]}"
do
  echo "Run $test"
  ./tools/TextComparer.sh "${test}.xml" "${test}.xml.expected"
done
