-- Starter A1 lessons with Arabic explanations. Idempotent: skipped when A1 lessons exist.
do $$
declare l uuid;
begin
  if exists (select 1 from public.lessons where cefr_level = 'A1') then return; end if;
  insert into public.lessons (cefr_level, position, title_de, title_ar, description_ar) values ('A1', 1, 'Begrüßung', 'التحية', 'أهم عبارات التحية والوداع، الرسمية وغير الرسمية.') returning id into l;
  insert into public.lesson_items (lesson_id, position, kind, german, arabic, example_de, example_ar, options, answer) values
    (l, 1, 'vocab', 'Hallo', 'مرحباً', 'Hallo, Anna!', 'مرحباً يا آنا!', null, null),
    (l, 2, 'vocab', 'Guten Morgen', 'صباح الخير', null, null, null, null),
    (l, 3, 'vocab', 'Guten Tag', 'نهارك سعيد (تحية رسمية في النهار)', null, null, null, null),
    (l, 4, 'vocab', 'Guten Abend', 'مساء الخير', null, null, null, null),
    (l, 5, 'vocab', 'Tschüss', 'مع السلامة (غير رسمي)', null, null, null, null),
    (l, 6, 'vocab', 'Auf Wiedersehen', 'إلى اللقاء (رسمي)', null, null, null, null),
    (l, 7, 'phrase', 'Wie geht es Ihnen?', 'كيف حالك؟ (رسمي)', null, null, null, null),
    (l, 8, 'phrase', 'Wie geht''s?', 'كيف الحال؟ (غير رسمي)', null, null, null, null),
    (l, 9, 'phrase', 'Danke, gut.', 'بخير، شكراً.', null, null, null, null),
    (l, 10, 'quiz', '', 'ماذا تعني "Guten Morgen"؟', null, null, '["صباح الخير", "مساء الخير", "مع السلامة"]'::jsonb, 0),
    (l, 11, 'quiz', '', 'كيف تقول "إلى اللقاء" بشكل رسمي؟', null, null, '["Auf Wiedersehen", "Tschüss", "Hallo"]'::jsonb, 0),
    (l, 12, 'quiz', '', 'ماذا تعني "Wie geht''s?"؟', null, null, '["كيف الحال؟", "ما اسمك؟", "من أين أنت؟"]'::jsonb, 0);
  insert into public.lessons (cefr_level, position, title_de, title_ar, description_ar) values ('A1', 2, 'Sich vorstellen', 'التعريف بالنفس', 'قل اسمك ومن أين أنت وأين تسكن.') returning id into l;
  insert into public.lesson_items (lesson_id, position, kind, german, arabic, example_de, example_ar, options, answer) values
    (l, 1, 'phrase', 'Ich heiße Ahmed.', 'اسمي أحمد.', null, null, null, null),
    (l, 2, 'phrase', 'Wie heißen Sie?', 'ما اسمك؟ (رسمي)', null, null, null, null),
    (l, 3, 'phrase', 'Wie heißt du?', 'ما اسمك؟ (غير رسمي)', null, null, null, null),
    (l, 4, 'phrase', 'Ich komme aus Syrien.', 'أنا من سوريا.', null, null, null, null),
    (l, 5, 'phrase', 'Woher kommst du?', 'من أين أنت؟', null, null, null, null),
    (l, 6, 'phrase', 'Ich wohne in Berlin.', 'أسكن في برلين.', null, null, null, null),
    (l, 7, 'phrase', 'Ich spreche Arabisch.', 'أتكلم العربية.', null, null, null, null),
    (l, 8, 'phrase', 'Freut mich!', 'تشرفت بمعرفتك!', null, null, null, null),
    (l, 9, 'quiz', '', 'ماذا تعني "Woher kommst du?"؟', null, null, '["من أين أنت؟", "أين تسكن؟", "كم عمرك؟"]'::jsonb, 0),
    (l, 10, 'quiz', '', 'أكمل الجملة: "Ich ___ Ahmed."', null, null, '["heiße", "komme", "wohne"]'::jsonb, 0),
    (l, 11, 'quiz', '', 'ماذا تعني "Ich wohne in Hamburg."؟', null, null, '["أسكن في هامبورغ.", "أنا من هامبورغ.", "أعمل في هامبورغ."]'::jsonb, 0);
  insert into public.lessons (cefr_level, position, title_de, title_ar, description_ar) values ('A1', 3, 'Zahlen 1–20', 'الأرقام من 1 إلى 20', 'عدّ بالألمانية من واحد إلى عشرين.') returning id into l;
  insert into public.lesson_items (lesson_id, position, kind, german, arabic, example_de, example_ar, options, answer) values
    (l, 1, 'vocab', 'eins', '١ – واحد', null, null, null, null),
    (l, 2, 'vocab', 'zwei', '٢ – اثنان', null, null, null, null),
    (l, 3, 'vocab', 'drei', '٣ – ثلاثة', null, null, null, null),
    (l, 4, 'vocab', 'vier', '٤ – أربعة', null, null, null, null),
    (l, 5, 'vocab', 'fünf', '٥ – خمسة', null, null, null, null),
    (l, 6, 'vocab', 'sechs', '٦ – ستة', null, null, null, null),
    (l, 7, 'vocab', 'sieben', '٧ – سبعة', null, null, null, null),
    (l, 8, 'vocab', 'acht', '٨ – ثمانية', null, null, null, null),
    (l, 9, 'vocab', 'neun', '٩ – تسعة', null, null, null, null),
    (l, 10, 'vocab', 'zehn', '١٠ – عشرة', null, null, null, null),
    (l, 11, 'vocab', 'zwölf', '١٢ – اثنا عشر', null, null, null, null),
    (l, 12, 'vocab', 'zwanzig', '٢٠ – عشرون', 'Ich bin zwanzig Jahre alt.', 'عمري عشرون سنة.', null, null),
    (l, 13, 'quiz', '', 'ما هو الرقم "sieben"؟', null, null, '["7", "6", "9"]'::jsonb, 0),
    (l, 14, 'quiz', '', 'ما هو الرقم "zwölf"؟', null, null, '["12", "11", "20"]'::jsonb, 0),
    (l, 15, 'quiz', '', 'كيف تكتب الرقم ٣ بالألمانية؟', null, null, '["drei", "zwei", "acht"]'::jsonb, 0);
  insert into public.lessons (cefr_level, position, title_de, title_ar, description_ar) values ('A1', 4, 'Die Familie', 'العائلة', 'أفراد العائلة مع أداة التعريف (der / die).') returning id into l;
  insert into public.lesson_items (lesson_id, position, kind, german, arabic, example_de, example_ar, options, answer) values
    (l, 1, 'vocab', 'die Mutter', 'الأم', null, null, null, null),
    (l, 2, 'vocab', 'der Vater', 'الأب', null, null, null, null),
    (l, 3, 'vocab', 'die Eltern', 'الوالدان', null, null, null, null),
    (l, 4, 'vocab', 'der Bruder', 'الأخ', null, null, null, null),
    (l, 5, 'vocab', 'die Schwester', 'الأخت', null, null, null, null),
    (l, 6, 'vocab', 'der Sohn', 'الابن', null, null, null, null),
    (l, 7, 'vocab', 'die Tochter', 'الابنة', null, null, null, null),
    (l, 8, 'vocab', 'die Großmutter', 'الجدة', null, null, null, null),
    (l, 9, 'phrase', 'Das ist meine Familie.', 'هذه عائلتي.', null, null, null, null),
    (l, 10, 'phrase', 'Ich habe zwei Brüder.', 'لدي أخوان.', null, null, null, null),
    (l, 11, 'quiz', '', 'ماذا تعني "die Schwester"؟', null, null, '["الأخت", "الأم", "الابنة"]'::jsonb, 0),
    (l, 12, 'quiz', '', 'ما كلمة "الأب" بالألمانية؟', null, null, '["der Vater", "der Bruder", "der Sohn"]'::jsonb, 0),
    (l, 13, 'quiz', '', 'ماذا تعني "die Eltern"؟', null, null, '["الوالدان", "الأجداد", "الأطفال"]'::jsonb, 0);
  insert into public.lessons (cefr_level, position, title_de, title_ar, description_ar) values ('A1', 5, 'Farben', 'الألوان', 'أسماء الألوان الأساسية.') returning id into l;
  insert into public.lesson_items (lesson_id, position, kind, german, arabic, example_de, example_ar, options, answer) values
    (l, 1, 'vocab', 'rot', 'أحمر', null, null, null, null),
    (l, 2, 'vocab', 'blau', 'أزرق', null, null, null, null),
    (l, 3, 'vocab', 'grün', 'أخضر', null, null, null, null),
    (l, 4, 'vocab', 'gelb', 'أصفر', null, null, null, null),
    (l, 5, 'vocab', 'schwarz', 'أسود', null, null, null, null),
    (l, 6, 'vocab', 'weiß', 'أبيض', null, null, null, null),
    (l, 7, 'vocab', 'braun', 'بني', null, null, null, null),
    (l, 8, 'vocab', 'grau', 'رمادي', null, null, null, null),
    (l, 9, 'phrase', 'Das Auto ist rot.', 'السيارة حمراء.', null, null, null, null),
    (l, 10, 'quiz', '', 'ماذا تعني "grün"؟', null, null, '["أخضر", "أزرق", "أصفر"]'::jsonb, 0),
    (l, 11, 'quiz', '', 'ما كلمة "أسود" بالألمانية؟', null, null, '["schwarz", "weiß", "grau"]'::jsonb, 0),
    (l, 12, 'quiz', '', 'السماء زرقاء: "Der Himmel ist ___."', null, null, '["blau", "rot", "braun"]'::jsonb, 0);
  insert into public.lessons (cefr_level, position, title_de, title_ar, description_ar) values ('A1', 6, 'Essen und Trinken', 'الطعام والشراب', 'كلمات وعبارات للمطعم والمطبخ.') returning id into l;
  insert into public.lesson_items (lesson_id, position, kind, german, arabic, example_de, example_ar, options, answer) values
    (l, 1, 'vocab', 'das Brot', 'الخبز', null, null, null, null),
    (l, 2, 'vocab', 'das Wasser', 'الماء', null, null, null, null),
    (l, 3, 'vocab', 'der Kaffee', 'القهوة', null, null, null, null),
    (l, 4, 'vocab', 'der Tee', 'الشاي', null, null, null, null),
    (l, 5, 'vocab', 'die Milch', 'الحليب', null, null, null, null),
    (l, 6, 'vocab', 'der Apfel', 'التفاحة', null, null, null, null),
    (l, 7, 'vocab', 'das Gemüse', 'الخضار', null, null, null, null),
    (l, 8, 'phrase', 'Ich habe Hunger.', 'أنا جائع.', null, null, null, null),
    (l, 9, 'phrase', 'Ich möchte einen Tee, bitte.', 'أريد شاياً من فضلك.', null, null, null, null),
    (l, 10, 'phrase', 'Die Rechnung, bitte.', 'الحساب من فضلك.', null, null, null, null),
    (l, 11, 'quiz', '', 'ماذا تعني "das Wasser"؟', null, null, '["الماء", "الحليب", "الشاي"]'::jsonb, 0),
    (l, 12, 'quiz', '', 'كيف تقول "أنا جائع"؟', null, null, '["Ich habe Hunger.", "Ich habe Durst.", "Ich bin müde."]'::jsonb, 0),
    (l, 13, 'quiz', '', 'ماذا تعني "Die Rechnung, bitte."؟', null, null, '["الحساب من فضلك.", "القائمة من فضلك.", "الماء من فضلك."]'::jsonb, 0);
  insert into public.lessons (cefr_level, position, title_de, title_ar, description_ar) values ('A1', 7, 'Die Wochentage', 'أيام الأسبوع', 'أيام الأسبوع تبدأ في ألمانيا يوم الاثنين.') returning id into l;
  insert into public.lesson_items (lesson_id, position, kind, german, arabic, example_de, example_ar, options, answer) values
    (l, 1, 'vocab', 'Montag', 'الاثنين', null, null, null, null),
    (l, 2, 'vocab', 'Dienstag', 'الثلاثاء', null, null, null, null),
    (l, 3, 'vocab', 'Mittwoch', 'الأربعاء', null, null, null, null),
    (l, 4, 'vocab', 'Donnerstag', 'الخميس', null, null, null, null),
    (l, 5, 'vocab', 'Freitag', 'الجمعة', null, null, null, null),
    (l, 6, 'vocab', 'Samstag', 'السبت', null, null, null, null),
    (l, 7, 'vocab', 'Sonntag', 'الأحد', null, null, null, null),
    (l, 8, 'phrase', 'Heute ist Montag.', 'اليوم هو الاثنين.', null, null, null, null),
    (l, 9, 'phrase', 'am Wochenende', 'في عطلة نهاية الأسبوع', null, null, null, null),
    (l, 10, 'quiz', '', 'ماذا تعني "Mittwoch"؟', null, null, '["الأربعاء", "الخميس", "الثلاثاء"]'::jsonb, 0),
    (l, 11, 'quiz', '', 'ما كلمة "الجمعة" بالألمانية؟', null, null, '["Freitag", "Samstag", "Sonntag"]'::jsonb, 0),
    (l, 12, 'quiz', '', 'أي يوم يأتي بعد Samstag؟', null, null, '["Sonntag", "Montag", "Freitag"]'::jsonb, 0);
  insert into public.lessons (cefr_level, position, title_de, title_ar, description_ar) values ('A1', 8, 'Die Uhrzeit', 'الوقت والساعة', 'اسأل عن الوقت وقل الساعة. انتبه: halb vier تعني الثالثة والنصف!') returning id into l;
  insert into public.lesson_items (lesson_id, position, kind, german, arabic, example_de, example_ar, options, answer) values
    (l, 1, 'phrase', 'Wie spät ist es?', 'كم الساعة؟', null, null, null, null),
    (l, 2, 'phrase', 'Es ist drei Uhr.', 'الساعة الثالثة.', null, null, null, null),
    (l, 3, 'vocab', 'halb vier', 'الثالثة والنصف (٣:٣٠)', null, null, null, null),
    (l, 4, 'vocab', 'Viertel nach zwei', 'الثانية والربع (٢:١٥)', null, null, null, null),
    (l, 5, 'vocab', 'Viertel vor fünf', 'الخامسة إلا ربعاً (٤:٤٥)', null, null, null, null),
    (l, 6, 'vocab', 'die Stunde', 'الساعة (مدة ٦٠ دقيقة)', null, null, null, null),
    (l, 7, 'vocab', 'die Minute', 'الدقيقة', null, null, null, null),
    (l, 8, 'vocab', 'morgens', 'صباحاً', null, null, null, null),
    (l, 9, 'vocab', 'abends', 'مساءً', null, null, null, null),
    (l, 10, 'quiz', '', 'ماذا تعني "halb vier"؟', null, null, '["3:30", "4:30", "4:00"]'::jsonb, 0),
    (l, 11, 'quiz', '', 'ماذا تعني "Wie spät ist es?"؟', null, null, '["كم الساعة؟", "كم عمرك؟", "أين المحطة؟"]'::jsonb, 0),
    (l, 12, 'quiz', '', 'ماذا تعني "Viertel nach zwei"؟', null, null, '["2:15", "1:45", "2:45"]'::jsonb, 0);
end;
$$;
