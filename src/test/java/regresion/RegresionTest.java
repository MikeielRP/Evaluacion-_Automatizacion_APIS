package regresion;

import com.intuit.karate.junit5.Karate;

class RegresionTest {

    @Karate.Test
    Karate testRegresion() {
        return Karate.run("regresion").relativeTo(getClass());
    }
}
