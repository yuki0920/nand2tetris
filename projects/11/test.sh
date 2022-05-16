targets=(
  "projects/11/Seven"
  "projects/11/ConvertToBin"
  "projects/11/Square"
  "projects/11/Average/"
  "projects/11/Pong"
  "projects/11/ComplexArrays"
)
for target in "${targets[@]}"
do
  echo "Compile $target"
  ruby projects/11/jack_analyzer/jack_analyzer.rb $target
done

tests=(
  "projects/11/Seven/Main"
  "projects/11/ConvertToBin/Main"
  "projects/11/Square/Main"
  "projects/11/Square/Square"
  "projects/11/Square/SquareGame"
  "projects/11/Average/Main"
  "projects/11/Pong/Ball"
  "projects/11/Pong/Bat"
  "projects/11/Pong/Main"
  "projects/11/Pong/PongGame"
  "projects/11/ComplexArrays/Main"
)
echo '----------------------------------------------------'
echo "Run Tokenizer tests"
for test in "${tests[@]}"
do
  echo "Run $test"
  ./tools/TextComparer.sh "${test}T.xml" "${test}T.expected.xml"
done

echo '----------------------------------------------------'
echo "Run Compilation Engine tests"
for test in "${tests[@]}"
do
  echo "Run $test"
  ./tools/TextComparer.sh "${test}.xml" "${test}.expected.xml"
done

echo '----------------------------------------------------'

echo "Run Compiler tests"
for test in "${tests[@]}"
do
  echo "Run Compiler $test"
  ./tools/TextComparer.sh "${test}.vm" "${test}.expected.vm"
done
