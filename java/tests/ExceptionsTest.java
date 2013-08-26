
import static utils.Utils.*;

public class ExceptionsTest {

    public static void strictFunction(Integer arg) {
        try {
            int number = arg;
            if (number < 0)
                throw new IllegalArgumentException("we do not accept negatives");
            System.out.println("Whee, strictFunction call is complete!");
        }
        catch (NullPointerException e) {
            System.out.println("Null pointer exception caught: " + e.getMessage());
        }
        catch (IllegalArgumentException e) {
            System.out.println("Illegal argument exception caught: " + e.getMessage());
            if (arg == -42)
                throw new RuntimeException("the negative answer is awful");
        }
        finally {
            System.out.println("strictFunction finally");
            if (arg != null && arg == 42)
                throw new RuntimeException("the answer is not accepted");
        }
    }

    public static void main(String[] args) {
        System.out.println("Simple test");
        System.out.println("Before exception");
        try {
            System.out.println("In try block");
            throw new IllegalArgumentException();
        }
        catch (IllegalArgumentException e) {
            System.out.println("Exception caught");
        }
        finally {
            System.out.println("Clean up");
        }
        System.out.println("After exception");

        System.out.println("Extendend test");
        strictFunction(null);
        strictFunction(-1);
        try {
            strictFunction(42);
        }
        catch (RuntimeException e) {
            System.out.println("Runtime exception caught: " + e.getMessage());
        }
        try {
            strictFunction(-42);
        }
        catch (RuntimeException e) {
            System.out.println("Runtime exception caught: " + e.getMessage());
        }
    }
}