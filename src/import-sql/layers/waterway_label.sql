CREATE OR REPLACE VIEW waterway_label_z8toz12 AS
    SELECT *
    FROM osm_water_linestring
    WHERE type IN ('river', 'canal');

CREATE OR REPLACE VIEW waterway_label_z13 AS
    SELECT *
    FROM osm_water_linestring
    WHERE type IN ('river', 'canal', 'stream', 'stream_intermittent');

CREATE OR REPLACE VIEW waterway_label_z14 AS
    SELECT *
    FROM osm_water_linestring
    WHERE type IN ('river', 'canal', 'stream', 'stream_intermittent', 'ditch', 'drain');

CREATE OR REPLACE VIEW waterway_label_layer AS (
    SELECT osm_id, timestamp, geometry FROM waterway_label_z8toz12
    UNION
    SELECT osm_id, timestamp, geometry FROM waterway_label_z13
    UNION
    SELECT osm_id, timestamp, geometry FROM waterway_label_z14
);

CREATE OR REPLACE FUNCTION waterway_label_changed_tiles(ts timestamp)
RETURNS TABLE (x INTEGER, y INTEGER, z INTEGER) AS $$
BEGIN
	RETURN QUERY (
		WITH changed_tiles AS (
		    SELECT DISTINCT c.osm_id, t.tile_x AS x, t.tile_y AS y, t.tile_z AS z
		    FROM waterway_label_layer AS c
            INNER JOIN LATERAL overlapping_tiles(c.geometry, 14) AS t ON c.timestamp = ts
		)

		SELECT c.x, c.y, c.z FROM waterway_label_z13toz14 AS l
		INNER JOIN changed_tiles AS c ON c.osm_id = l.osm_id AND c.z BETWEEN 13 AND 14
        UNION

		SELECT c.x, c.y, c.z FROM waterway_label_z8toz12 AS l
		INNER JOIN changed_tiles AS c ON c.osm_id = l.osm_id AND c.z BETWEEN 8 AND 12
	);
END;
$$ LANGUAGE plpgsql;
