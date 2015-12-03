# Lifecastor Command Line

**Usage:** `ruby lifecastor.rb [options]... [plan property file of your choice]`

    Options are explained below. They can be combined.

    To make a simplest run, type the following, then hit enter key.

        ruby lifecastor.rb

        This uses the default parameters from the included file plan.properites.
        Feel free to modify the parameters as you wish.

    To run on your own plan property file named 'my_plan_properties', type:

        ruby lifecastor.rb my_plan_properties

    To combine the above run with option -v, type:

        ruby lifecastor.rb -v my_plan_properties

**Options:**

    -b, --brief                      Output brief resutls of bankrupt info. Use -v to see more detaills.

    -c, --chart                      Chart the resutls as configured by your plan.propreties file.

    -d, --diff                       Show the difference between last and current results.

    -q, --quiet                      Output nothing to the standard output.

    -t, --taxed_savings              Tax savings at short term capital gain tax rates which are the same as regular income tax rates.

    -v, --verbose                    Output the complete resutls.

    -h, --help                       Show this message


# Features

This is an application for [*Personal Finance Life-long Forcaste*](http://tranquil-headland-5582.herokuapp.com/).

* Easy to modify input parameters in file plan.properties allow you to run endless what-if simulations so that you can understand your financial future. 

* See the big pictures of your financial future under dynamic probabilistic income, expense, and savings. 

* Analyze the impact of inflation, social security, and retirement age on your financial future. 

* Statistically forecast your estate and wealth. 

* Display you simulated wealth paths into the future.

Please send comments and suggestions to John at johnzhu00@gmail.com.


# Sample Runs

## Run 1
```
ruby lifecastor.rb 

SUMMARY
  Bankrupt probability:      17.0%
  Average bankrupt age:      97.0
  Avg horizon wealth:     454,216
```

## Run 2
```
ruby lifecastor.rb -v

Simulation 1
Age        Income      Taxable      Federal        State    Total Tax      Expense    Shortfall    Net Worth
 40        100000        88600        20400         7000        27400        49486        23114       127287
 41        103263        91863        21159         7228        28387        44501        30375       162694
 42        105028        93628        24157         7352        31509        54941        18578       187920
 43        108118        96718        24962         7568        32530        62189        13399       208977
 44        111098        99698        25738         7777        33515        81746        -4163       211108
 45        113262       101862        26302         7928        34230        52464        26569       246161
 46        116245       104845        27078         8137        35215        55599        25431       282124
 47        120895       109495        28289         8463        36752        77955         6188       300005
 48        123946       112546        29084         8676        37760        60549        25637       336702
 49        127588       116188        30032         8931        38963        50701        37924       385397
 50        132446       121046        31297         9271        40568        63586        28292       429950
 51        135637       124237        32128         9495        41623        48152        45863       493070
 52        140321       128921        33348         9822        43170        62285        34866       545483
 53        143880       132480        34274        10072        44346        70643        28891       597199
 54        148362       136962        35441        10385        45827        46926        55609       675983
 55        152755       141355        36585        10693        47278        48499        56978       757140
 56        157446       146046        37807        11021        48828        65178        43440       833336
 57        163254       151854        39319        11428        50747        82829        29677       897221
 58        166823       155423        40249        11678        51926        60755        54142       987494
 59        170461       159061        41196        11932        53128        77052        40280      1066142
 60        176491       165091        42766        12354        55121        63813        57557      1165161
 61        180754       169354        43876        12653        56529        74951        49274      1262876
 62        185618       174218        45143        12993        58136        90055        37427      1345993
 63        191191       179791        46594        13383        59977        63391        67822      1463877
r 64        202895       191495        49642        14203        63845        74777        64273      1587641
Rr 65         22121        10721         1376         1548         2924        79740       -60544      1588737
Rr 66         22121        10721         1376         1548         2924        67337       -48140      1601477
Rr 67         22121        10721         1376         1548         2924        65121       -45925      1615298
Rr 68         22121        10721         1376         1548         2924        61309       -42113      1636683
Rr 69         22121        10721         1376         1548         2924        58692       -39495      1662478
Rr 70         22121        10721         1376         1548         2924        68848       -49651      1672648
Rr 71         22121        10721         1376         1548         2924        81408       -62211      1678345
Rr 72         22121        10721         1376         1548         2924        82736       -63540      1684590
Rr 73         22121        10721         1376         1548         2924        82345       -63148      1690829
Rr 74         22121        10721         1376         1548         2924        94358       -75161      1687661
Rr 75         22121        10721         1376         1548         2924        84209       -65013      1689789
Rr 76         22121        10721         1376         1548         2924       101620       -82424      1670111
Rr 77         22121        10721         1376         1548         2924       101103       -81906      1649028
Rr 78         22121        10721         1376         1548         2924        84817       -65620      1649090
Rr 79         22121        10721         1376         1548         2924       103145       -83948      1637572
Rr 80         22121        10721         1376         1548         2924       104285       -85089      1619374
Rr 81         22121        10721         1376         1548         2924       107881       -88685      1598798
Rr 82         22121        10721         1376         1548         2924       108236       -89039      1576506
Rr 83         22121        10721         1376         1548         2924       112556       -93359      1543017
Rr 84         22121        10721         1376         1548         2924        99127       -79930      1520181
Rr 85         22121        10721         1376         1548         2924       125478      -106281      1469498
Rr 86         22121        10721         1376         1548         2924       124714      -105517      1421670
Rr 87         22121        10721         1376         1548         2924       117088       -97892      1381105
Rr 88         22121        10721         1376         1548         2924       119293      -100097      1340581
Rr 89         22121        10721         1376         1548         2924       131694      -112498      1283104
Rr 90         22121        10721         1376         1548         2924       140135      -120939      1216995
Rr 91         22121        10721         1376         1548         2924       144616      -125420      1137328
Rr 92         22121        10721         1376         1548         2924       146551      -127355      1050078
Rr 93         22121        10721         1376         1548         2924       146870      -127674       962474
Rr 94         22121        10721         1376         1548         2924       165880      -146684       856682
Lr 95          5105            0            0          153          153       122707      -117755       772594
Lr 96          5105            0            0          153          153       113754      -108802       696185
Lr 97          5105            0            0          153          153       114509      -109557       613428
Lr 98          5105            0            0          153          153       133950      -128999       510703
Simulation 2
Age        Income      Taxable      Federal        State    Total Tax      Expense    Shortfall    Net Worth
 40        100000        88600        20400         7000        27400        39988        32612       136071
 41        103356        91956        21180         7235        28415        56153        18788       159973
 42        107261        95861        24739         7508        32247        62642        12372       178724
 43        110751        99351        25648         7753        33400        48243        29108       214393
 44        114008       102608        26496         7981        34476        55961        23570       246870
 45        118568       107168        27683         8300        35983        57539        25047       281388
 46        122190       110790        28626         8553        37180        60712        24298       315957
 47        125977       114577        29613         8818        38431        52921        34625       364207
 48        129201       117801        30452         9044        39496        67951        21754       400917
 49        132723       121323        31369         9291        40660        43521        48543       466658
 50        136089       124689        32245         9526        41772        60531        33786       520522
 51        139753       128353        33200         9783        42982        44690        52081       592694
 52        144099       132699        34331        10087        44418        70056        29624       644449
 53        148370       136970        35444        10386        45829        59512        43029       711217
 54        153185       141785        36697        10723        47420        63677        42088       784877
 55        158604       147204        38108        11102        49211        59881        49511       867425
 56        164394       152994        39616        11508        51124        68508        44763       944573
 57        169346       157946        40906        11854        52760        71330        45256      1026385
 58        175340       163940        42467        12274        54740        64273        56327      1122686
 59        181415       170015        44048        12699        56747        61150        63518      1232821
 60        187868       176468        45729        13151        58880        72442        56546      1338574
 61        194476       183076        47450        13613        61063        79317        54096      1454245
 62        200140       188740        48924        14010        62934        73231        63974      1573711
 63        206535       195135        59623        14457        74081        77620        54834      1691728
r 64        215855       204455        62484        15110        77594        69444        68817      1829700
Rr 65         22121        10721         1376         1548         2924        67287       -48090      1848913
Rr 66         22121        10721         1376         1548         2924        51486       -32290      1885537
Rr 67         22121        10721         1376         1548         2924        71579       -52383      1904795
Rr 68         22121        10721         1376         1548         2924        66278       -47082      1938688
Rr 69         22121        10721         1376         1548         2924        88503       -69307      1952064
Rr 70         22121        10721         1376         1548         2924        71989       -52793      1976546
Rr 71         22121        10721         1376         1548         2924        84099       -64903      1990888
Rr 72         22121        10721         1376         1548         2924        81425       -62228      2020121
Rr 73         22121        10721         1376         1548         2924        98609       -79412      2022317
Rr 74         22121        10721         1376         1548         2924        72916       -53719      2050117
Rr 75         22121        10721         1376         1548         2924        80507       -61311      2067474
Rr 76         22121        10721         1376         1548         2924        94148       -74952      2083796
Rr 77         22121        10721         1376         1548         2924        82909       -63713      2097264
Rr 78         22121        10721         1376         1548         2924        81592       -62396      2122524
Rr 79         22121        10721         1376         1548         2924        95508       -76311      2115135
Rr 80         22121        10721         1376         1548         2924        94868       -75672      2126774
Rr 81         22121        10721         1376         1548         2924       118688       -99491      2106543
Rr 82         22121        10721         1376         1548         2924       107170       -87973      2099226
Rr 83         22121        10721         1376         1548         2924       115151       -95954      2088165
Rr 84         22121        10721         1376         1548         2924       114562       -95365      2074857
Rr 85         22121        10721         1376         1548         2924       109594       -90398      2048201
Rr 86         22121        10721         1376         1548         2924       116810       -97614      2027970
Rr 87         22121        10721         1376         1548         2924       126523      -107327      1997534
Rr 88         22121        10721         1376         1548         2924       121477      -102280      1978687
Rr 89         22121        10721         1376         1548         2924       143247      -124050      1932491
Rr 90         22121        10721         1376         1548         2924       138765      -119568      1887732
Rr 91         22121        10721         1376         1548         2924       132010      -112814      1847944
Rr 92         22121        10721         1376         1548         2924       139200      -120004      1801982
Rr 93         22121        10721         1376         1548         2924       144002      -124806      1757137
Rr 94         22121        10721         1376         1548         2924       159152      -139956      1688811
Lr 95          5105            0            0          153          153       103671       -98719      1658927
Lr 96          5105            0            0          153          153       117364      -112412      1622825
Lr 97          5105            0            0          153          153       119699      -114747      1569769
Lr 98          5105            0            0          153          153       111386      -106434      1525608
Simulation 3
Age        Income      Taxable      Federal        State    Total Tax      Expense    Shortfall    Net Worth
 40        100000        88600        20400         7000        27400        62675         9925       114525
 41        102726        91326        21034         7191        28225        51735        22766       141757
 42        105594        94194        24305         7392        31696        53902        19996       167360
 43        108926        97526        25172         7625        32797        68719         7410       181804
 44        112456       101056        26092         7872        33963        45107        33386       221994
 45        115930       104530        26996         8115        35111        67821        12997       244602
 46        120147       108747        28094         8410        36505        58871        24772       278038
 47        124303       112903        29176         8701        37878        70118        16307       306318
 48        129017       117617        30404         9031        39435        74154        15428       334637
 49        132361       120961        31275         9265        40540        75826        15995       362759
 50        135499       124099        32092         9485        41577        84730         9192       386184
 51        138709       127309        32928         9710        42637        58187        37884       441031
 52        142472       131072        33908         9973        43881        79523        19068       480321
 53        146083       134683        34848        10226        45074        47769        53240       551173
 54        150400       139000        35972        10528        46500        59642        44258       616767
 55        154551       143151        37053        10819        47872        73534        33146       673675
 56        158336       146936        38039        11084        49122        57030        52184       755189
 57        163694       152294        39434        11459        50893        62139        50663       834784
 58        167356       155956        40388        11715        52102        66422        48832       918868
 59        171238       159838        41398        11987        53385        77651        40202       997199
 60        175393       163993        42480        12278        54758        63654        56982      1092648
 61        180971       169571        43933        12668        56601        76881        47489      1179011
 62        185413       174013        45090        12979        58069        84052        43293      1271859
 63        189816       178416        46236        13287        59523        87434        42859      1368053
r 64        198820       187420        48581        13917        62498        86397        49925      1475564
Rr 65         22121        10721         1376         1548         2924        57502       -38306      1499041
Rr 66         22121        10721         1376         1548         2924        71754       -52558      1510361
Rr 67         22121        10721         1376         1548         2924        64070       -44874      1530814
Rr 68         22121        10721         1376         1548         2924        70504       -51307      1533491
Rr 69         22121        10721         1376         1548         2924        67520       -48323      1544475
Rr 70         22121        10721         1376         1548         2924        64850       -45653      1554464
Rr 71         22121        10721         1376         1548         2924        78173       -58977      1555136
Rr 72         22121        10721         1376         1548         2924        88826       -69630      1540619
Rr 73         22121        10721         1376         1548         2924        94630       -75433      1530765
Rr 74         22121        10721         1376         1548         2924        91995       -72798      1521758
Rr 75         22121        10721         1376         1548         2924       105117       -85921      1500265
Rr 76         22121        10721         1376         1548         2924        86558       -67362      1497473
Rr 77         22121        10721         1376         1548         2924       106377       -87181      1466723
Rr 78         22121        10721         1376         1548         2924        99111       -79915      1445263
Rr 79         22121        10721         1376         1548         2924       107845       -88648      1419928
Rr 80         22121        10721         1376         1548         2924       110445       -91249      1383955
Rr 81         22121        10721         1376         1548         2924       115084       -95887      1348551
Rr 82         22121        10721         1376         1548         2924       109815       -90618      1317684
Rr 83         22121        10721         1376         1548         2924       138797      -119601      1239591
Rr 84         22121        10721         1376         1548         2924       125425      -106229      1173900
Rr 85         22121        10721         1376         1548         2924       129077      -109881      1110044
Rr 86         22121        10721         1376         1548         2924       142427      -123231      1030330
Rr 87         22121        10721         1376         1548         2924       127394      -108198       964302
Rr 88         22121        10721         1376         1548         2924       139707      -120510       875418
Rr 89         22121        10721         1376         1548         2924       143790      -124593       788533
Rr 90         22121        10721         1376         1548         2924       142169      -122972       699292
Rr 91         22121        10721         1376         1548         2924       141875      -122678       603242
Rr 92         22121        10721         1376         1548         2924       149791      -130594       497640
Rr 93         22121        10721         1376         1548         2924       159131      -139935       377221
Rr 94         22121        10721         1376         1548         2924       173805      -154609       237414
Lr 95          5105            0            0          153          153       120357      -115405       131435
Lr 96          5105            0            0          153          153       129550      -124598        12402
Lr 97          5105            0            0          153          153       125101      -120149      -107247
      BANKRUPT at age 97!
Lr 98          5105            0            0          153          153       129072      -124120      -236159
.
.
.
.
.
.
Simulation 100
Age        Income      Taxable      Federal        State    Total Tax      Expense    Shortfall    Net Worth
 40        100000        88600        20400         7000        27400        43069        29531       133736
 41        102968        91568        21090         7208        28298        54851        19819       158852
 42        105814        94414        24362         7407        31769        69241         4804       169215
 43        107712        96312        24856         7540        32396        47000        28316       204037
 44        111606       100206        25870         7812        33683        49787        28137       240638
 45        115140       103740        26790         8060        34850        74405         5885       254830
 46        119192       107792        27845         8343        36189        64207        18795       283255
 47        122793       111393        28783         8596        37379        49730        35684       329492
 48        126187       114787        29667         8833        38500        64314        23373       365933
 49        130212       118812        30715         9115        39830        68608        21774       401839
 50        134333       122933        31788         9403        41191        63820        29321       446733
 51        138748       127348        32938         9712        42650        55360        40738       507163
 52        143233       131833        34106        10026        44132        62361        36740       564944
 53        147622       136222        35249        10334        45582        56045        45994       632766
 54        152209       140809        36443        10655        47098        40516        64595       723732
 55        156543       145143        37572        10958        48530        63105        44908       798827
 56        161449       150049        38849        11301        50151        73816        37482       865014
 57        166501       155101        40165        11655        51820        59519        55163       959967
 58        171867       160467        41562        12031        53593        76725        41549      1043707
 59        176183       164783        42686        12333        55019        60824        60341      1143786
 60        181629       170229        44104        12714        56818        69826        54985      1241708
 61        187050       175650        45516        13093        58609        63447        64994      1359205
 62        193639       182239        47232        13555        60786        77391        55462      1467284
 63        197844       186444        48327        13849        62176        75517        60151      1586657
r 64        208775       197375        60311        14614        74925        92926        40924      1688713
Rr 65         22121        10721         1376         1548         2924        71627       -52431      1702656
Rr 66         22121        10721         1376         1548         2924        78638       -59441      1708675
Rr 67         22121        10721         1376         1548         2924        68039       -48843      1724816
Rr 68         22121        10721         1376         1548         2924        74357       -55160      1740361
Rr 69         22121        10721         1376         1548         2924        81880       -62683      1753635
Rr 70         22121        10721         1376         1548         2924        80793       -61596      1756093
Rr 71         22121        10721         1376         1548         2924        82465       -63268      1767826
Rr 72         22121        10721         1376         1548         2924        67711       -48515      1796229
Rr 73         22121        10721         1376         1548         2924        92218       -73021      1795616
Rr 74         22121        10721         1376         1548         2924        88586       -69389      1793340
Rr 75         22121        10721         1376         1548         2924        93868       -74672      1793708
Rr 76         22121        10721         1376         1548         2924        99796       -80600      1781331
Rr 77         22121        10721         1376         1548         2924        99853       -80657      1769484
Rr 78         22121        10721         1376         1548         2924       107262       -88065      1751756
Rr 79         22121        10721         1376         1548         2924       104725       -85528      1733747
Rr 80         22121        10721         1376         1548         2924       112239       -93042      1713977
Rr 81         22121        10721         1376         1548         2924       105917       -86720      1699253
Rr 82         22121        10721         1376         1548         2924       113965       -94769      1673148
Rr 83         22121        10721         1376         1548         2924       125710      -106514      1631032
Rr 84         22121        10721         1376         1548         2924       124212      -105015      1594779
Rr 85         22121        10721         1376         1548         2924       133018      -113821      1537422
Rr 86         22121        10721         1376         1548         2924       127476      -108279      1491560
Rr 87         22121        10721         1376         1548         2924       136815      -117619      1430570
Rr 88         22121        10721         1376         1548         2924       135434      -116238      1373430
Rr 89         22121        10721         1376         1548         2924       128018      -108821      1318931
Rr 90         22121        10721         1376         1548         2924       137349      -118153      1254304
Rr 91         22121        10721         1376         1548         2924       154933      -135736      1166791
Rr 92         22121        10721         1376         1548         2924       164560      -145364      1070588
Rr 93         22121        10721         1376         1548         2924       154321      -135124       979204
Rr 94         22121        10721         1376         1548         2924       158737      -139541       878079
Lr 95          5105            0            0          153          153       121529      -116577       795733
Lr 96          5105            0            0          153          153       120267      -115315       709877
Lr 97          5105            0            0          153          153       117017      -112065       624624
Lr 98          5105            0            0          153          153       121332      -116380       530860

SUMMARY
  Bankrupt probability:      17.0%
  Average bankrupt age:      97.0
  Avg horizon wealth:     454,216
```

# Sample Plan Property File

```
# All parameters are grouped into two sets for the primary bread maker and his spouse. 
# Those of the spouse are suffixed by an underscore '_'.
#
age=40
age_to_retire=65
# discount factor after retirement for BOTH spouses: the expense after retirement is dropped to this percentage of the expense before retirement
expense_after_retirement = 0.8

# this models your senior year baseline annual health cost: your health cost will grow upwards non-linearly based on this base in such a way that it starts to grow upwards non-linearly at age 55, double at 70, triple at 80, six times at 90; set it to zero if you don't want to simulate senior year health cost by Lifecastor
health_cost_base = 1000.0
# this allows you to shift when senior year health cost starts to grow upwards non-linearly: 0 means that the cost starts to grow at age 55; -10 means 10 years sooner at age 45, 15 means 15 years later at age 70; if you are healthy, set it to positive value;
shift = 0

life_expectancy = 95
# discount factor for the surviving spouse after the primary is passed away: assuming that life_expectancy is the shorter than life_expectancy_ of the spouse
expense_after_life_expectancy = 0.7

# annual income
income=100000
# income growth mean annual rate and standard deviation: the yearly salary growth percentage is normally distributed with a mean and standard deviation (sd)
increase_mean=0.03
increase_sd  =0.005

##### spouse data #####
age_=38
age_to_retire_=62
# this models your senior year baseline annual health cost: your health cost will grow upwards non-linearly based on this base in such a way that it starts to grow upwards non-linearly at age 55, double at 70, triple at 80, six times at 90; set it to zero if you don't want to simulate senior year health cost by Lifecastor
health_cost_base_ = 1000.0
# this allows you to shift when senior year health cost starts to grow upwards non-linearly: 0 means that the cost starts to grow at age 55; -10 means 10 years sooner at age 45, 15 means 15 years later at age 70; if you are healthy, set it to positive value;
shift_ = 0

# this is supposed to be greater or equal to life_expectancy specified above and determines the length of the planning hozizon.
life_expectancy_ = 98
# if spouse doesn't have income, set these three parameters to 0 and give the spousal SS benefit factor a non-zero value like 0.3 (30%)
income_=0
increase_mean_=0.00
increase_sd_  =0.000
# if the spouse has her own income and claims her own ss, set this to 0; this is non-zero only when claiming spousal ss benefits instead of spousal's own ss
spousal_ss_benefit_factor = 0.3

# normally distributed expense: this is the most controllable factor in personal financial planning! To carefully control your spending is the most important and fundamental part of personal financial planning.
expense_mean=40000
expense_sd  =10000

# existing known MONTHLY expense: eg mortgage, car payment, child support, ...;  it will be converted into a yearly expense automatically
monthly_expense=1000
start_year     =1995
end_year       =2025

# Only one of these 5 filing status should be selected. Select one by uncommenting it and commenting out the currently uncommented one.
#filing_status=single
#filing_status=married_filing_separately
filing_status=married_filing_jointly
#filing_status=head_of_household
#filing_status=qualifying_window

# the total savings at the beginning of the planning horizon: this is the total available fund for any shortfall going forward
savings=100000
savings_rate_mean=0.04
savings_rate_sd  =0.003

# normally distributed inflation: adjust it to see its effect on you!  Currently, it inflates only your expenses.
inflation_mean=0.028
inflation_sd  =0.005

total_number_of_simulation_runs=100

# Choose charts from the following columns in any order:
# ["Income", "Taxable", "Federal", "State", "Expense", "Shortfall", "Net Worth"]
#
# For example: 
# what_to_chart1="Expense", "Income"
# will chart two lines, one for expense and the other for income on chart 1.
#
# For another example: 
# what_to_chart2="Net Worth"
# will chart only one line for Net Worth on chart 2.
#
#what_to_chart1="Income", "Taxable", "Federal", "State", "Expense", "Shortfall"
what_to_chart1="Income", "Federal", "State", "Expense", "Shortfall"
what_to_chart2="Net Worth"

# Changing this to any other positive integer results statistically 
# the same output, only with a different random sampling
seed_offset=3330

# Discount factor for the first two years of the planning horizon 
# to avoid unrealistic premature bankrupt
# Set it to 1.0 if you don't want use it
first_two_year_factor = 1.0
```
# Disclaimer

This Lifecastor financial planning software is hypothetical in nature and intended to help you in making decisions on your financial future based on the information that you have provided and reviewed.

IMPORTANT: The projections or other information generated by Lifecastor regarding the likelihood of various investment outcomes are hypothetical in nature, do not reflect actual investment results, and are not guarantees of future results.

Please send comments and suggestions to John at johnzhu00@gmail.com.
