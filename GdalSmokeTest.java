import org.gdal.gdal.Driver;
import org.gdal.gdal.gdal;
import org.gdal.ogr.ogr;

public class GdalSmokeTest {

    public static void main(String[] args) {
        gdal.AllRegister();
        ogr.RegisterAll();

        int driverCount = gdal.GetDriverCount();
        String version = gdal.VersionInfo();

        if (driverCount <= 0) {
            throw new IllegalStateException("GDAL driver count is zero");
        }

        Driver firstDriver = gdal.GetDriver(0);
        System.out.println("GDAL version: " + version);
        System.out.println("Driver count: " + driverCount);
        System.out.println("First driver: " + firstDriver.getShortName() + " - " + firstDriver.getLongName());
        System.out.println("GDAL smoke test passed");
    }
}