#!/dis/sh

load std test

ROOT=/Users/zubr/dev/distributed/inferno-java
JAVAC=os -d $ROOT`{pwd} javac

subfn test-name {
	result=SystemIOTest
}

fn compile-test {
	report INF 7 'Compiling test $1'
	$JAVAC $1.java
	for c in $1^*.class {java/j2d -g $c}
}
fn clean-test {
	report INF 7 'Cleaning test $1'
	rm *.dis *.s *.class
}
fn run-test {
	report INF 7 'Running test $1'
	java/jvm $1
}

test := ${test-name}
compile-test $test
#run-test $test