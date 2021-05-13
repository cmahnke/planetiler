package com.onthegomap.flatmap.geo;

import org.locationtech.jts.geom.CoordinateSequence;
import org.locationtech.jts.geom.CoordinateXY;
import org.locationtech.jts.geom.Envelope;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.impl.PackedCoordinateSequence;
import org.locationtech.jts.geom.util.GeometryTransformer;
import org.locationtech.jts.io.WKBReader;

public class GeoUtils {

  public static final GeometryFactory gf = new GeometryFactory();
  public static final WKBReader wkbReader = new WKBReader(gf);

  private static final double WORLD_RADIUS_METERS = 6_378_137;
  private static final double WORLD_CIRCUMFERENCE_METERS = Math.PI * 2 * WORLD_RADIUS_METERS;
  private static final double DEGREES_TO_RADIANS = Math.PI / 180;
  private static final double RADIANS_TO_DEGREES = 180 / Math.PI;
  private static final double MAX_LAT = getWorldLat(-0.1);
  private static final double MIN_LAT = getWorldLat(1.1);
  public static Envelope WORLD_BOUNDS = new Envelope(0, 1, 0, 1);
  public static Envelope WORLD_LAT_LON_BOUNDS = toLatLonBoundsBounds(WORLD_BOUNDS);
  public static final GeometryTransformer UNPROJECT_WORLD_COORDS = new GeometryTransformer() {
    @Override
    protected CoordinateSequence transformCoordinates(CoordinateSequence coords, Geometry parent) {
      if (coords.getDimension() != 2) {
        throw new IllegalArgumentException("Dimension must be 2, was: " + coords.getDimension());
      }
      if (coords.getMeasures() != 0) {
        throw new IllegalArgumentException("Measures must be 0, was: " + coords.getMeasures());
      }
      CoordinateSequence copy = new PackedCoordinateSequence.Double(coords.size(), 2, 0);
      for (int i = 0; i < coords.size(); i++) {
        copy.setOrdinate(i, 0, getWorldLon(coords.getX(i)));
        copy.setOrdinate(i, 1, getWorldLat(coords.getY(i)));
      }
      return copy;
    }
  };
  public static final GeometryTransformer PROJECT_WORLD_COORDS = new GeometryTransformer() {
    @Override
    protected CoordinateSequence transformCoordinates(CoordinateSequence coords, Geometry parent) {
      if (coords.getDimension() != 2) {
        throw new IllegalArgumentException("Dimension must be 2, was: " + coords.getDimension());
      }
      if (coords.getMeasures() != 0) {
        throw new IllegalArgumentException("Measures must be 0, was: " + coords.getMeasures());
      }
      CoordinateSequence copy = new PackedCoordinateSequence.Double(coords.size(), 2, 0);
      for (int i = 0; i < coords.size(); i++) {
        copy.setOrdinate(i, 0, getWorldX(coords.getX(i)));
        copy.setOrdinate(i, 1, getWorldY(coords.getY(i)));
      }
      return copy;
    }
  };

  public static Geometry latLonToWorldCoords(Geometry geom) {
    return PROJECT_WORLD_COORDS.transform(geom);
  }

  public static Geometry worldToLatLonCoords(Geometry geom) {
    return UNPROJECT_WORLD_COORDS.transform(geom);
  }

  public static Envelope toLatLonBoundsBounds(Envelope worldBounds) {
    return new Envelope(
      getWorldLon(worldBounds.getMinX()),
      getWorldLon(worldBounds.getMaxX()),
      getWorldLat(worldBounds.getMinY()),
      getWorldLat(worldBounds.getMaxY()));
  }

  public static Envelope toWorldBounds(Envelope lonLatBounds) {
    return new Envelope(
      getWorldX(lonLatBounds.getMinX()),
      getWorldX(lonLatBounds.getMaxX()),
      getWorldY(lonLatBounds.getMinY()),
      getWorldY(lonLatBounds.getMaxY())
    );
  }

  public static double getWorldLon(double x) {
    return x * 360 - 180;
  }

  public static double getWorldLat(double y) {
    double n = Math.PI - 2 * Math.PI * y;
    return RADIANS_TO_DEGREES * Math.atan(0.5 * (Math.exp(n) - Math.exp(-n)));
  }

  public static double getWorldX(double lon) {
    return (lon + 180) / 360;
  }

  public static double getWorldY(double lat) {
    if (lat <= MIN_LAT) {
      return 1.1;
    }
    if (lat >= MAX_LAT) {
      return -0.1;
    }
    double sin = Math.sin(lat * DEGREES_TO_RADIANS);
    return 0.5 - 0.25 * Math.log((1 + sin) / (1 - sin)) / Math.PI;
  }

  public static final GeometryTransformer ProjectWorldCoords = new GeometryTransformer() {
    @Override
    protected CoordinateSequence transformCoordinates(CoordinateSequence coords, Geometry parent) {
      if (coords.getDimension() != 2) {
        throw new IllegalArgumentException("Dimension must be 2, was: " + coords.getDimension());
      }
      if (coords.getMeasures() != 0) {
        throw new IllegalArgumentException("Measures must be 0, was: " + coords.getMeasures());
      }
      CoordinateSequence copy = new PackedCoordinateSequence.Double(coords.size(), 2, 0);
      for (int i = 0; i < coords.size(); i++) {
        copy.setOrdinate(i, 0, getWorldX(coords.getX(i)));
        copy.setOrdinate(i, 1, getWorldY(coords.getY(i)));
      }
      return copy;
    }
  };

  private static final double QUANTIZED_WORLD_SIZE = Math.pow(2, 31);
  private static final long LOWER_32_BIT_MASK = (1L << 32) - 1L;

  public static long encodeFlatLocation(double lon, double lat) {
    double worldX = getWorldX(lon);
    double worldY = getWorldY(lat);
    long x = (long) (worldX * QUANTIZED_WORLD_SIZE);
    long y = (long) (worldY * QUANTIZED_WORLD_SIZE);
    return (x << 32) | y;
  }

  public static double decodeWorldY(long encoded) {
    return ((double) (encoded & LOWER_32_BIT_MASK)) / QUANTIZED_WORLD_SIZE;
  }

  public static double decodeWorldX(long encoded) {
    return ((double) (encoded >> 32)) / QUANTIZED_WORLD_SIZE;
  }

  public static double getZoomFromLonLatBounds(Envelope envelope) {
    Envelope worldBounds = GeoUtils.toWorldBounds(envelope);
    return getZoomFromWorldBounds(worldBounds);
  }

  public static double getZoomFromWorldBounds(Envelope worldBounds) {
    double maxEdge = Math.max(worldBounds.getWidth(), worldBounds.getHeight());
    return Math.max(0, -Math.log(maxEdge) / Math.log(2));
  }

  public static double metersPerPixelAtEquator(int zoom) {
    return WORLD_CIRCUMFERENCE_METERS / Math.pow(2, zoom + 8);
  }

  public static long longPair(int a, int b) {
    return (((long) a) << 32L) | (((long) b) & LOWER_32_BIT_MASK);
  }

  public static int first(int pair) {
    return pair >> 16;
  }

  public static int second(int pair) {
    return (pair << 16) >> 16;
  }

  public static Geometry point(double x, double y) {
    return gf.createPoint(new CoordinateXY(x, y));
  }
}