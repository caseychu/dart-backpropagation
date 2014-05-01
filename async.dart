import 'dart:async';

// Runs a function periodically, but start waiting only after the function's
// done. (The default timer doesn't wait for the function to finish, so we
// could up with functions stacking on top of each other.)
void async(int ms, Function fn) {
	var wrapped;
	wrapped = () {
		new Timer(new Duration(milliseconds: ms), () {
			fn();
			wrapped();
		});
	};
	wrapped();
}

// Loop a function for a certain amount of time.
int until(int ms, Function fn) {
	var stopwatch = new Stopwatch()..start();
	int count = 0;
	while (stopwatch.elapsedMilliseconds < ms) {
		fn();
		count++;
	}
	return count;
}