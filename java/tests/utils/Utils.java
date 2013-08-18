
package utils;

public class Utils {

	public static class AssertionFailedException extends java.lang.RuntimeException {
		public AssertionFailedException(String msg) {
			super(msg);
			System.err.println("Asserion failed: " + msg);
		}
	}

	private Utils() {
	}

	public static void assertEquals(int expected, int found) throws AssertionFailedException {
		assertEquals(expected, found, "expected " + expected + " but found " + found);
	}
	public static void assertEquals(int expected, int found, String msg) throws AssertionFailedException {
		if (expected != found)
			throw new AssertionFailedException(msg);
	}


	public static void assertEquals(long expected, long found) throws AssertionFailedException {
		assertEquals(expected, found, "expected " + expected + " but found " + found);
	}
	public static void assertEquals(long expected, long found, String msg) throws AssertionFailedException {
		if (expected != found)
			throw new AssertionFailedException(msg);
	}

	public static void assertEquals(float expected, float found) throws AssertionFailedException {
		assertEquals(expected, found, "expected " + expected + " but found " + found);
	}
	public static void assertEquals(float expected, float found, String msg) throws AssertionFailedException {
		if (expected != found)
			throw new AssertionFailedException(msg);
	}

	public static void assertEquals(double expected, double found) throws AssertionFailedException {
		assertEquals(expected, found, "expected " + expected + " but found " + found);
	}
	public static void assertEquals(double expected, double found, String msg) throws AssertionFailedException {
		if (expected != found)
			throw new AssertionFailedException(msg);
	}

	public static void assertEquals(Object expected, Object found) throws AssertionFailedException {
		assertEquals(expected, found, "expected " + expected + " but found " + found);
	}
	public static void assertEquals(Object expected, Object found, String msg) throws AssertionFailedException {
		if (!expected.equals(found))
			throw new AssertionFailedException(msg);
	}

	public static void main(String[] args) {
		// This is only for convenience, so that
		// test system may assume this is also a test
	}
}