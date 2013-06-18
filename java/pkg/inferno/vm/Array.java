// special Array wrapper class; all fields 'transient' to thwart serialization

package inferno.vm;
public final
class Array implements Cloneable, java.io.Serializable {
	private transient Object data;	// Dis array
	private transient int	 ndim;	// number of dimensions
	private transient Object adt;	// 'ref Class' of elt. type (nil if primitive)
	private transient int	 etype;	// primitive elt. type code (0 if reference)
}
