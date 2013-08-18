
import static utils.Utils.*;
import java.lang.Math;

public class MathTest {

    public static void main(String[] args) {
    	assertEquals(42, 6 * 7);
    	assertEquals(0.5, 1.0 / 2);
    	assertEquals(1, Math.sqrt(1));
    	assertEquals(3, Math.sqrt(9));
    	assertEquals(82.5, 6 * 7 / 1 + 45 - 9.0 / 2);
    }
}