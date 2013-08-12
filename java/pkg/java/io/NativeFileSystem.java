package java.io;

/**
 * FileSystem implementation for Inferno vm.
 *
 * @author kabbi
 */
public class NativeFileSystem extends FileSystem {

    @Override
    public native char getSeparator();

    @Override
    public native char getPathSeparator();

    @Override
    public native String normalize(String path);

    @Override
    public native int prefixLength(String path);

    @Override
    public native String resolve(String parent, String child);

    @Override
    public native String getDefaultParent();

    @Override
    public native String fromURIPath(String path);

    @Override
    public native boolean isAbsolute(File f);

    @Override
    public native String resolve(File f);

    @Override
    public native String canonicalize(String path) throws IOException;

    @Override
    public native int getBooleanAttributes(File f);

    @Override
    public native boolean checkAccess(File f, int access);

    @Override
    public native boolean setPermission(File f, int access, boolean enable, boolean owneronly);

    @Override
    public native long getLastModifiedTime(File f);

    @Override
    public native long getLength(File f);

    @Override
    public native boolean createFileExclusively(String pathname) throws IOException;

    @Override
    public native boolean delete(File f);

    @Override
    public native String[] list(File f);

    @Override
    public native boolean createDirectory(File f);

    @Override
    public native boolean rename(File f1, File f2);

    @Override
    public native boolean setLastModifiedTime(File f, long time);

    @Override
    public native boolean setReadOnly(File f);

    @Override
    public native File[] listRoots();

    @Override
    public native long getSpace(File f, int t);

    @Override
    public native int compare(File f1, File f2);

    @Override
    public native int hashCode(File f);

}
