package jp.raohmaru.rokoban 
{

/**
 * Representa un mapa del juego.
 * @author raohmaru
 */
public class Map 
{
	public var	data :Array,
				tilesetID :uint,
				record :uint,
				string :String;
	
	/**
	 * Obtiene el número de objetivos del mapa.
	 */
	public function get numTargets() :uint
	{
		return string.split(Tile.GOAL).length - 1;
	}
	
	
	
	public function Map(data :Array, tileset_id :uint, record :uint=0)
	{
		this.data = data;		this.tilesetID = tileset_id;
		this.record = record;
		
		string = data.join("");
	}
}
}