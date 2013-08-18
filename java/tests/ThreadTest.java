
import static utils.Utils.*;

public class ThreadTest {

    private static class Integer {
        private int data;

        Integer(int data) {
            this.data = data;
        }

        int getData() {
            return data;
        }

        void setData(int data) {
            this.data = data;
        }

    }

    public static void main(String[] args) throws InterruptedException {
        final Integer var = new Integer(0);
        Thread testThread = new Thread(new Runnable() {
            @Override
            public void run() {
                var.setData(42);
            }
        });
        testThread.start();
        testThread.join();
        assertEquals(42, var.getData());

        Thread testThread1 = new Thread(new Runnable() {
            @Override
            public void run() {
                for (int i = 0; i < 2000; i++) {
                    synchronized (var) {
                        var.setData(var.getData() + 1);
                    }
                }
            }
        });
        Thread testThread2 = new Thread(new Runnable() {
            @Override
            public void run() {
                for (int i = 0; i < 1000; i++) {
                    synchronized (var) {
                        var.setData(var.getData() - 1);
                    }
                }
            }
        });
        testThread1.start();
        testThread2.start();
        testThread1.join();
        testThread2.join();
        assertEquals(1042, var.getData());
    }
}