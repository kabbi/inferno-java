
import static utils.Utils.*;

/**
 * This file is just to test wm/deb and sbl
 * file generation. It is useless by itself.
 */

public class DebugTest {
	private static final int SLEEP_AMOUNT = 10000;

	public static int someAnotherFunction() {
		return 6-7;
	}

	public static void someFunction() throws InterruptedException {
		Thread.sleep(SLEEP_AMOUNT);
		long val = System.currentTimeMillis() / 2;
		for (int i = 0; i < 100; i++) {
			val *= someAnotherFunction();
			throw new IllegalArgumentException("use your debugger");
		}
	}

    public static void main(String[] args) throws InterruptedException {
    	assertEquals(42, 6 * 7);
    	Thread.sleep(SLEEP_AMOUNT);
    	someFunction();
    }
}