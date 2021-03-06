local developers = [
  19824262, 91787483, //ps4
  71082530, 91888359, 93770394, //xbox
  42719923, 42143907, //d.suslov
  91582970, 91884879, //a.vinokurov
  35851, 71481055, //winlay
  7716, //s.kolganov
  38777395, //s.miroshnichenko
  10735393, //a.trifonov
  23, //dark@gaijin.ru
  28, //anton@gaijin.ru
  4143, //i.kalinin@gaijin.ru
  12604, //a.nagorniy@gaijin.ru
  84365, //anton@gaijinent.com
  99298, //v.ivannikov@gaijin.ru
  174556, //s.zvyagin@gaijin.ru
  177154, //todace@gmail.com
  673811, //a.serkov@gaijin.ru
  1477209, //s.dmitriev@gaijin.ru
  1512469, //a.polyakov@gaijin.ru
  11899955, //d.titov@gaijin.ru
  1942786, //e.kononenko@gaijin.ru
  2284416, //s.ryazanov@gaijin.ru
  2952603, //m.tsart@gaijin.ru
  4509561, //d.evlahov@gaijin.ru
  4848872, //squier@gaijin.ru
  5703377, //m.avramenko@gaijin.ru
  5907567, //d.dmitriev@gaijin.ru
  8699765, //d.kapelin@gaijin.ru
  10151130, //k.klimenko@gaijin.ru
  10408816, //k.stepanovich@gaijin.ru
  11644369, //v.lukyanenko@gaijin.ru
  11685323, //enyrian@gaijin.ru
  21582318, //d.wierzbowski@gaijin.ru
  24929925, //d.shulepov@gaijin.ru
  28953782, //v.schumann@gaijin.ru
  31108039, //p.sergeev@gaijin.ru
  31346359, //b.belkov@gaijin.ru
  33929677, //a.timofeev@gaijin.ru
  37583395, //m.sinko@gaijin.ru
  40388507, //d.chernjuk@gaijin.ru
  43034050, //e.guskov@gaijin.ru
  58074603, //a.petrov@gaijin.ru
  62552267, //d.foktov@gaijin.ru
  63583289, //a.shcherbakov@gaijin.ru
  63179658, //o.volchelyuk@gaijin.ru
  75659458, //d.nechipurenko@gaijin.ru
  77244191, //i.vopilov@gaijin.ru
  78992476, //i.vopilov+test@gaijin.ru
  78983890, //a.potapov@gaijin.ru
  83231409, //v.volchkevich@gaijin.ru
  83948240, //a.sobolev@gaijin.ru
  84125747, //a.tolkach@gaijin.ru
  85095871, //d.pobedinskiy@gaijin.ru
  85392211, //d.granetchi@gaijin.ru
  86058421, //d.gricuks@gaijin.ru
  85583028, //v.udalov@gaijin.ru
  87067439, //g.szaloki@gaijin.team
  88813232, //a.tolkach@gaijin.team
  89823217, //m.trapikov@gaijin.team
  91671069, //a.safonov@gaijin.team
  94184962, //p.popov@gaijin.team
  94922978, //a.astapov@gaijin.team
  95790732, //n.vashkis@gaijin.team
  99033687, //y.kravchenko@gaijin.team
  102192348, //d.sagun@gaijin.team
  102194371, //a.kopari@gaijin.team
  102830260, //s.vorobev@gaijin.team
  103262729, //l.perneky@gaijin.team
  104089313, //m.martins@gaijin.team
  104627308, //t.morgan@gaijin.team
  104669672, //k.kulikov@gaijin.team
  104968308, //z.vegvari@gaijin.team
  68763457, //a.azarov@gaijin.ru
  46391820, //m.brahner@gaijinent.com
  46061930 //brahnerm@gmail.com
]

local debug_permissions = {
  debug_server_data = true
  debug_monetization = true
  debug_shop_show = true
  debug_items_show = true
}

local default_permissions = debug_permissions.map(@(_) false)
local cPermissions = { DEFAULT = default_permissions }

foreach(userid in developers)
  cPermissions[userid] <- debug_permissions

return cPermissions
 