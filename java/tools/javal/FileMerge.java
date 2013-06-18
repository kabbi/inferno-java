package javal;

import java.io.File;
import java.io.FileOutputStream;
import java.io.FileInputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.EOFException;


class FileMerge
{
	/**
	 * open the two files and merge. The "tmpname"
	 * is the newer generated file, name is the older
	 * file and will become the merged file
	 */
	static void Merge( String name, String tmpname ) throws IOException
	{
		// rename 'name'
		String oldname = "old_"+ name;
		File   old_f   = new File(oldname);
		if ( old_f.exists() )
			old_f.delete();
		new File( name ).renameTo( old_f );

		// open output for merged file
		DataOutputStream      merge;
		DataInputStream  ftmp, fold;
		
		merge = new DataOutputStream(new FileOutputStream( name ) );
		ftmp  = new DataInputStream( new FileInputStream( tmpname ) );
		fold  = new DataInputStream( new FileInputStream( oldname ) );

		while ( true )
		{
			try
			{
				ReadNWrite( ftmp, merge, "#>>" );
				Ignore( ftmp, "#<<" );
			}
			catch ( EOFException ee )
			{
				WriteRest( fold, merge );
				break;
			}
			try
			{
				Ignore( fold, "#>>" );
				ReadNWrite( fold, merge, "#<<" );
			}
			catch ( EOFException ee )
			{
				WriteRest( ftmp, merge );
				break;
			}
		}

		fold.close();
		ftmp.close();
		merge.close();
		new File( tmpname ).delete();

	}


	private static void ReadNWrite( DataInputStream fin, DataOutputStream fout, String pat ) throws IOException
	{
		String line;

		do
		{
			line = fin.readLine();
			if ( line == null ) throw new EOFException();
			fout.writeBytes( line );
			fout.writeBytes( linesep );
		}
		while ( line.indexOf(pat) == -1 );
	}


	private static void Ignore( DataInputStream fin, String pat ) throws IOException
	{
		String line;
		do
		{
			line = fin.readLine();
			if ( line == null ) throw new EOFException();
		}
		while ( line.indexOf(pat) == -1 );
	}

	private static void WriteRest( DataInputStream fin, DataOutputStream fout ) throws IOException
	{
		while ( true )
		{
			String line = fin.readLine();
			if (line == null) 
				return;
			fout.writeBytes(line);
			fout.writeBytes( linesep );
		}
	}

	private static String linesep = System.getProperties().getProperty("line.separator");

}
