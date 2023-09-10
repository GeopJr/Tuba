struct TestBase83Decode {
    public string encoded;
    public int decoded;
}

struct TestBlurhashValidity {
    public string blurhash;
    public bool valid;
}

struct TestBlurhashRatio {
    public string blurhash;
    public int x;
    public int y;
}

struct TestBlurhashData {
    public string blurhash;
    public uint8 data_1;
    public uint8 data_2;
    public uint8 data_3;
    public uint8 data_4;
}

const TestBase83Decode[] BASE83_DECODE_TESTS = {
    { "tuba", 31837176 },
    { "0m0R1", 27448018 },
    { "P7btDt@Pap!szZkkEoSnK5e%cg!QC4", 0 },
    { "VPmm5Ft%!9tG5hC7J^vwHToZoFJVKLDgY78kE%dPaiLB^^rv^P9f6UwR*p@c!UB", 0 },
    { "L00000fQfQfQfQfQfQfQfQfQfQfQ", -718366762 },
    { "LGF5]+Yk^6#M@-5c,1J5@[or[Q6.", 934061677 },
    { "L6PZfSjE.AyE_3t7t7R**0o#DgR4", -1746869106 },
    { "LKO2:N%2Tw=w]~RBVZRi};RPxuwH", -1074644314 },
    { "LEHLk~WB2yk8pyo0adR*.7kCMdnj", 1224798277 }
};

const TestBlurhashValidity[] BLURHASH_VALIDITY_TESTS = {
    { "invalidblurhash", false },
    { "tuba", false },
    { "6chars", false },
    { "L00000fQfQfQfQfQfQfQfQfQfQfQ", true },
    { "LGF5]+Yk^6#M@-5c,1J5@[or[Q6.", true },
    { "L6PZfSjE.AyE_3t7t7R**0o#DgR4", true },
    { "LKO2:N%2Tw=w]~RBVZRi};RPxuwH", true },
    { "LEHLk~WB2yk8pyo0adR*.7kCMdnj", true },
    { "LEHLk~WB2yk8pyo0adR*.7kCMdnj.", false }
};

const TestBlurhashRatio[] BLURHASH_RATIO_TESTS = {
    { "L00000fQfQfQfQfQfQfQfQfQfQfQ", 4, 3 },
    { "LGF5]+Yk^6#M@-5c,1J5@[or[Q6.", 4, 3 },
    { "L6PZfSjE.AyE_3t7t7R**0o#DgR4", 4, 3 },
    { "LKO2:N%2Tw=w]~RBVZRi};RPxuwH", 4, 3 },
    { "LEHLk~WB2yk8pyo0adR*.7kCMdnj", 4, 3 },
    { "oHF5]+Yk^6#M9wKS@-5b,1J5O[V=@[or[k6.O[TL};FxngOZE3NgjMFxS#OtcXnzj]OYNeR:JCs9", 6, 6 },
    { "o6PZfSi_.AyE8^m+_3t7t7R*WBs,*0o#DgR4.Tt,_3R*D%xt%MIpMcV@%itSI9R5Iot7-:IoM{%L", 6, 6 },
    { "oKN]Rv%2Tw=wR6cE]~RBVZRip0W9};RPxuwH%3s8tLOtxZ%gixtQI.ENa0NZIVt6%1j^M_bcRPX9", 6, 6 },
    { "oEHLk~WB2yk8$Nxupyo0adR*=ss:.7kCMdnjx]S2S#M|%1%2ENRiSis.slNHW:WBogaekBW;ofo0", 6, 6 }
};

const TestBlurhashData[] BLURHASH_TO_DATA_TESTS = {
    { "invalid", 0, 0, 0, 0 },
    { "L00000fQfQfQfQfQfQfQfQfQfQfQ", 6, 6, 6, 255 },
    { "LGF5]+Yk^6#M@-5c,1J5@[or[Q6.", 173, 129, 188, 255 },
    { "L6PZfSjE.AyE_3t7t7R**0o#DgR4", 230, 228, 225, 255 },
    { "LKO2:N%2Tw=w]~RBVZRi};RPxuwH", 243, 194, 173, 255 },
    { "LEHLk~WB2yk8pyo0adR*.7kCMdnj", 159, 175, 181, 255 }
};

public void test_base83_decode () {
    foreach (var test_base83_decode in BASE83_DECODE_TESTS) {
        var res = Tuba.Blurhash.Base83.decode (test_base83_decode.encoded);

        assert_cmpint (res, CompareOperator.EQ, test_base83_decode.decoded);
    }
}

public void test_blurhash_validity () {
    foreach (var test_blurhash_validity in BLURHASH_VALIDITY_TESTS) {
        var res = Tuba.Blurhash.is_valid_blurhash (test_blurhash_validity.blurhash, null, null, null, null);

        if (test_blurhash_validity.valid) {
            assert_true (res);
        } else {
            assert_false (res);
        }
    }
}

public void test_blurhash_ratio () {
    foreach (var test_blurhash_ratio in BLURHASH_RATIO_TESTS) {
        var res_x = 0;
        var res_y = 0;
        var res = Tuba.Blurhash.is_valid_blurhash (test_blurhash_ratio.blurhash, null, out res_x, out res_y, null);

        assert_true (res);
        assert_cmpint (res_x, CompareOperator.EQ, test_blurhash_ratio.x);
        assert_cmpint (res_y, CompareOperator.EQ, test_blurhash_ratio.y);
    }
}

public void test_blurhash_data () {
    foreach (var test_blurhash_data in BLURHASH_TO_DATA_TESTS) {
        var res = Tuba.Blurhash.decode_to_data (test_blurhash_data.blurhash, 10, 10);

        if (test_blurhash_data.blurhash == "invalid") {
            assert (res == null);
        } else {
            assert (res != null);
            assert_cmpuint (res[8], CompareOperator.EQ, test_blurhash_data.data_1);
            assert_cmpuint (res[9], CompareOperator.EQ, test_blurhash_data.data_2);
            assert_cmpuint (res[10], CompareOperator.EQ, test_blurhash_data.data_3);
            assert_cmpuint (res[11], CompareOperator.EQ, test_blurhash_data.data_4);
        }
    }
}

public int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/test_base83_decode", test_base83_decode);
    Test.add_func ("/test_blurhash_validity", test_blurhash_validity);
    Test.add_func ("/test_blurhash_ratio", test_blurhash_ratio);
    Test.add_func ("/test_blurhash_data", test_blurhash_data);
    return Test.run ();
}
