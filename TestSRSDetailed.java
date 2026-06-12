import org.gdal.gdal.gdal;
import org.gdal.osr.SpatialReference;

public class TestSRSDetailed {
    public static void main(String[] args) {
        System.out.println("Step 1: Loading GDAL library...");
        try {
            System.loadLibrary("gdalalljni");
            System.out.println("  OK - gdalalljni loaded");
        } catch (UnsatisfiedLinkError e) {
            System.err.println("  FAIL - Failed to load gdalalljni: " + e.getMessage());
        }

        System.out.println("\nStep 2: Calling gdal.AllRegister()...");
        try {
            gdal.AllRegister();
            System.out.println("  OK - GDAL registered");
        } catch (Exception e) {
            System.err.println("  FAIL: " + e.getMessage());
            e.printStackTrace();
        }

        System.out.println("\nStep 3: Creating SpatialReference...");
        try {
            SpatialReference srs = new SpatialReference();
            System.out.println("  OK - SpatialReference created!");

            System.out.println("\nStep 4: Importing EPSG:4326...");
            srs.ImportFromEPSG(4326);
            System.out.println("  OK - EPSG imported!");
            System.out.println("  WKT: " + srs.ExportToWkt());

        } catch (UnsatisfiedLinkError e) {
            System.err.println("  FAIL - UnsatisfiedLinkError: " + e.getMessage());
            e.printStackTrace();
        } catch (Exception e) {
            System.err.println("  FAIL - Exception: " + e.getMessage());
            e.printStackTrace();
        }

        System.out.println("\n=== All tests completed ===");
    }
}
