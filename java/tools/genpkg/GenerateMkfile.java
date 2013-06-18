
import java.io.*;

public class GenerateMkfile {

	public static void main(String[] args) {
		if (args.length == 0) {
			System.out.println("Generates or updates the mkfile for java");
			System.out.println("package in inferno java subsystem.");
			System.out.println();
			System.out.println("Usage: specify the package dir");
			return;
		}
		
		File dir = new File(args[0]);
		if (!dir.exists() || !dir.isDirectory()) {
			System.out.println("The path must be existing directory");
			return;
		}
		
		StringBuilder result = new StringBuilder();
		result.append("TARG=\\").append('\n');
		
		File[] files = dir.listFiles();
		for (File f: files) {
			if (f.isFile() && f.getName().endsWith(".java"))
				result.append('\t').append(f.getName()).append("\\\n");
		}
	}

}

