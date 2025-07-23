package io.flyisnow.gdal;

import org.gdal.gdal.Dataset;
import org.gdal.gdal.Driver;
import org.gdal.gdal.gdal;
import org.gdal.gdalconst.gdalconst;
import org.gdal.ogr.ogr;

import ai.djl.Device;
import ai.djl.ndarray.NDManager;
import ai.djl.ndarray.NDArray;
import ai.djl.ndarray.types.DataType;
import ai.djl.ndarray.types.Shape;

public class MainApplication {
    static {
        gdal.AllRegister();
        ogr.RegisterAll();
    }

    public static void main(String[] args) {
        NDManager manager = NDManager.newBaseManager(Device.cpu());
        NDArray zeros = manager.ones(new Shape(100, 100), DataType.FLOAT32);
        System.out.println("hello");
        System.out.println(zeros.getShape());
        writePng("test.png", zeros);
    }

    public static void writePng(String filePath, NDArray varArr) {
        Driver dstDriver = gdal.GetDriverByName("mem");
        Shape shape = varArr.getShape();
        int rows = (int)shape.get(0);
        int columns =(int) shape.get(1);
        Dataset dst = dstDriver.Create("", columns,rows,  1, gdalconst.GDT_Byte);
        dst.GetRasterBand(1).WriteRaster(0, 0, columns, rows, varArr.reshape(-1).toFloatArray());
        Driver pngDriver = gdal.GetDriverByName("PNG");
        Dataset pngDs = pngDriver.CreateCopy(filePath, dst, 0);

        pngDs.FlushCache();
        dst.delete();

    }

}