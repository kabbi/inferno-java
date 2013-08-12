
import java.io.*;

public class UpdateJavaPackages {
	
	private File sourcePath;
	
	UpdateJavaPackages(String sourcePath) {
		this.sourcePath = new File(sourcePath);
		if (!this.sourcePath.exists() || !this.sourcePath.isDirectory())
			throw new IllegalArgumentException("Bad source path!");
	}
	
	private String relativePath(File base, File file) {
		if (file.getAbsolutePath().equals(base.getAbsolutePath()))
			return "/";
		return file.getAbsolutePath().substring(base.getAbsolutePath().length() + 1);
	}
	
	private int getDirLevel(File path) {
		return relativePath(sourcePath, path).split("/").length;
	}
	
	private String generateTargSection(File[] files) {
		boolean success = false;
		StringBuilder result = new StringBuilder();
		result.append("TARG=\\").append('\n');
		for (File f: files) {
			if (f.isFile() && f.getName().endsWith(".java")) {
				String className = f.getName();
				// strip .java extension
				className = className.substring(0, className.lastIndexOf('.'));
				// add to mkfile
				result.append('\t').append(className).append(".dis\\\n");
				success = true;
			}
		}
		if (!success)
			return null;
		return result.toString();
	}
	private String generateDirsSection(File[] files) {
		boolean success = false;
		StringBuilder result = new StringBuilder();
		result.append("DIRS=\\").append('\n');
		for (File f: files) {
			if (f.isDirectory()) {
				result.append('\t').append(f.getName()).append("\\\n");
				success = true;
			}
		}
		if (!success)
			return null;
		return result.toString();
	}
	
	private void updateMkfile(File file) {
		// a bit hacky...
		file.delete();
		createMkfile(file);
	}
	
	private void createMkfile(File file) {
		try {
			File dir = file.getParentFile();
			PrintWriter writer = new PrintWriter(file);
			
			writer.print("<");
			// assume we have config in two folders higher
			int level = getDirLevel(dir) + 2;
			while (level-- > 0)
				writer.print("../");
			writer.print("mkconfig");
			writer.println();
			writer.println();
			File[] files = dir.listFiles();

			String dirs = generateDirsSection(files);
			if (dirs != null)
				writer.println(dirs);
			
			String targ = generateTargSection(files);
			if (targ != null)
				writer.println(targ);
			
			if (targ != null) {
				writer.println("DISBIN=$ROOT/java/dis/java/java/" + relativePath(sourcePath, dir));
				writer.println();
				writer.println("<$ROOT/mkfiles/mkjava");
			}
			
			if (dirs != null)
				writer.println("<$ROOT/mkfiles/mksubdirs");

			if (dirs == null && targ == null) {
				// Dummy entry to do anything
				writer.println("install:");
				writer.println("\techo");
			}
			
			writer.close();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}
	}
	
	private void processDir(File path) {
		System.out.println("Processing " + path.getPath());
		File[] files = path.listFiles();
		
		// walk all the dirs in source folder
		for (File f: files)
			if (f.isDirectory())
				processDir(f);
		
		File mkfile = new File(path.getPath() + "/mkfile");
		if (!mkfile.exists())
			createMkfile(mkfile);
		else
			updateMkfile(mkfile);
	}
	public void run() {
		processDir(sourcePath);
	}

	public static void main(String[] args) {
		if (args.length == 0) {
			System.out.println("Generates or updates mkfiles for java");
			System.out.println("packages in inferno java subsystem.");
			System.out.println();
			System.out.println("Usage: <source> <target>");
			System.out.println("Usage: <source>");
			System.out.println("\tsource - the path to unpacked src.zip from jdk");
			System.out.println("\ttarget - absolute path to /java/pkg/ in inferno root dir");
			return;
		}
		
		try {
			UpdateJavaPackages updater = new UpdateJavaPackages(args[0]);
			updater.run();
		}
		catch (IllegalArgumentException e) {
			System.out.println("Error: " + e.getMessage());
		}
	}

}
