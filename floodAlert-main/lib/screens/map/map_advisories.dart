import 'package:flutter/material.dart';
import '../../models/street_model.dart';
import '../../widgets/advisory_section.dart';

List<AdvisoryItem> municipalityAdvisories(double r, Street st) {
  final isOneway = st.oneway == true;

  final base = <AdvisoryItem>[
    const AdvisoryItem(
      title: "جاهزية ميدانية",
      lines: [
        "تفعيل جولة ميدانية سريعة لمصارف المياه والمنخفضات.",
        "تجهيز فريق طوارئ/مقاول لفتح المناهل وإزالة العوائق.",
      ],
      icon: Icons.support_agent,
    ),
    AdvisoryItem(
      title: "تنظيم حركة السير",
      lines: [
        "تجهيز نقاط تحويل/إغلاق عند أماكن تجمع المياه.",
        if (isOneway)
          "ملاحظة: الشارع اتجاه واحد — تأكدي من مسار التحويل البديل."
        else
          "الشارع اتجاهين — يفضّل فصل المسارات/تخفيف السرعة.",
      ],
      icon: Icons.traffic,
    ),
  ];

  if (r >= 0.75) {
    return [
      const AdvisoryItem(
        title: "إجراء فوري (Critical)",
        lines: [
          "إغلاق مقاطع حرجة فوراً عند بدء الجريان/ارتفاع المياه.",
          "تفعيل تنبيه عام للسكان القريبين (رسائل/مكبرات).",
          "تواصل مباشر مع الدفاع المدني وتحديد نقطة تمركز.",
        ],
        icon: Icons.warning_amber_rounded,
        emphasis: true,
      ),
      ...base,
      const AdvisoryItem(
        title: "حماية البنية التحتية",
        lines: [
          "مراقبة العبارات/القنوات القريبة لاحتمال انسداد.",
          "منع الوقوف العشوائي قرب المناهل ومخارج المياه.",
        ],
        icon: Icons.construction,
      ),
    ];
  }

  if (r >= 0.60) {
    return [
      const AdvisoryItem(
        title: "استعداد عالي (High)",
        lines: [
          "تجهيز إغلاق جزئي/تحويل مؤقت خلال 1–2 ساعة عند الحاجة.",
          "زيادة المراقبة في نقاط تجمع المياه والمناطق المنخفضة.",
        ],
        icon: Icons.report,
        emphasis: true,
      ),
      ...base,
    ];
  }

  if (r >= 0.30) {
    return [
      const AdvisoryItem(
        title: "مراقبة (Medium)",
        lines: [
          "تنظيف سريع للمصارف القريبة ومراجعة نقاط الانسداد السابقة.",
          "تنبيه فرق الصيانة للاستجابة السريعة عند زيادة الهطول.",
        ],
        icon: Icons.visibility,
      ),
      ...base,
    ];
  }

  return [
    const AdvisoryItem(
      title: "طبيعي (Low)",
      lines: [
        "متابعة دورية فقط.",
        "توثيق أي نقاط تجمع مياه لإدراجها في خطة تحسين مستقبلية.",
      ],
      icon: Icons.check_circle,
    ),
    ...base,
  ];
}

List<AdvisoryItem> schoolAdvisories(
  double r, {
  required int forecastHorizonHours,
}) {
  if (r >= 0.75) {
    return [
      AdvisoryItem(
        title: "قرار مبكر خلال $forecastHorizonHours ساعة",
        lines: const [
          "يوصى بتعليق الدوام/التحول للتعليم عن بُعد.",
          "إرسال تنبيه رسمي للأهالي الآن (لأن القرار مبكر).",
        ],
        icon: Icons.school,
        emphasis: true,
      ),
      const AdvisoryItem(
        title: "إجراءات داخل المدرسة",
        lines: [
          "إلغاء الطابور والأنشطة الخارجية فوراً.",
          "منع الطلاب من الاقتراب من الساحات المنخفضة ومداخل الماء.",
          "تجهيز غرفة طوارئ واتصال مع أولياء الأمور.",
        ],
        icon: Icons.shield,
      ),
      const AdvisoryItem(
        title: "التنسيق",
        lines: [
          "التواصل مع البلدية/الدفاع المدني لمتابعة الحالة.",
          "تحديد نقطة تجمع آمنة داخل المدرسة وإبلاغ الكادر.",
        ],
        icon: Icons.call,
      ),
    ];
  }

  if (r >= 0.60) {
    return [
      AdvisoryItem(
        title: "تقييم تعطيل الدوام خلال $forecastHorizonHours ساعة",
        lines: const [
          "تحضير قرار احترازي: تأخير دوام/تعليق جزئي حسب تحديثات الطقس.",
          "إرسال تنبيه مبكر للأهالي (احتمال تغيير الدوام).",
        ],
        icon: Icons.schedule,
        emphasis: true,
      ),
      const AdvisoryItem(
        title: "احتياطات تشغيل",
        lines: [
          "تقليل الحركة الخارجية ومراقبة البوابات.",
          "تجهيز مسار آمن لخروج الطلاب بعيداً عن الشارع الرئيسي.",
        ],
        icon: Icons.directions_walk,
      ),
    ];
  }

  if (r >= 0.30) {
    return [
      const AdvisoryItem(
        title: "استعداد متوسط",
        lines: [
          "مراجعة جاهزية الطوارئ ووسائل الاتصال.",
          "تذكير الطلاب بعدم الاقتراب من تجمعات المياه.",
        ],
        icon: Icons.info,
      ),
      const AdvisoryItem(
        title: "مراقبة",
        lines: [
          "متابعة تحديثات الطقس كل 3 ساعات.",
          "التأكد من نظافة المصارف القريبة من بوابة المدرسة.",
        ],
        icon: Icons.visibility,
      ),
    ];
  }

  return const [
    AdvisoryItem(
      title: "الوضع طبيعي",
      lines: [
        "دوام طبيعي مع متابعة دورية.",
        "تحديث قائمة أرقام الطوارئ والتأكد من جاهزية الإسعافات الأولية.",
      ],
      icon: Icons.check_circle,
    ),
  ];
}
