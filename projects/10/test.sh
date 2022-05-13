targets=(
  "projects/10/ArrayTest/"
  "projects/10/ExpressionLessSquare/"
  "projects/10/Square/"
)
for target in "${targets[@]}"
do
  echo "Compile $target"
  ruby projects/10/jack_analyzer/jack_analyzer.rb $target
done

tests=(
  "projects/10/ArrayTest/Main"
  "projects/10/ExpressionLessSquare/Main"
  "projects/10/ExpressionLessSquare/Square"
  "projects/10/ExpressionLessSquare/SquareGame"
  "projects/10/Square/Main"
  "projects/10/Square/Square"
  "projects/10/Square/SquareGame"
)
echo '----------------------------------------------------'
echo "Run Tokenizer tests"
for test in "${tests[@]}"
do
  echo "Run $test"
  ./tools/TextComparer.sh "${test}T.xml" "${test}T.xml.expected"
done

echo '----------------------------------------------------'
echo "Run Compiler tests"
for test in "${tests[@]}"
do
  echo "Run $test"
  ./tools/TextComparer.sh "${test}.xml" "${test}.xml.expected"
done
