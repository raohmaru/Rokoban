package jp.raohmaru.rokoban 
{
import flash.display.DisplayObject;
import flash.system.ApplicationDomain;

/**
 * Clase estática que almacena los gráficos (tilesets) utilizados en el juego.
 * @author raohmaru
 */
public class Tileset 
{
	private static var	_tilesets :Array = [];
	public static var	current :uint;
						
	public static function get length() :uint
	{
		return _tilesets.length;
	}
	
	
	
	/**
	 * Añade un nuevo tileset (la raíz de un SWF de donde extraer las clases).
	 */
	public static function add(tileset :DisplayObject) :void
	{
		_tilesets.push(tileset.loaderInfo.applicationDomain);
	}
	
	/**
	 * Obtiene una referencia a una clase con el gráfico. Si el tileset actual no tiene dicho gráfico,
	 * retorna uno por defecto (del primer tileset insertado).
	 */
	public static function getClass(name :String) :Class
	{
		try
		{
			return ApplicationDomain(_tilesets[current]).getDefinition(name) as Class;
		}
		catch(e :Error)
		{
			return ApplicationDomain(_tilesets[0]).getDefinition(name) as Class;
		}
		
		return null;
	}
}
}