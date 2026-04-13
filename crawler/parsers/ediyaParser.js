const cheerio = require('cheerio');
const { normalizeCategory } = require('../utils/categoryMapper');

function normalizeText(value) {
  if (value === undefined || value === null) return null;

  const text = String(value)
    .replace(/\u00a0/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  if (!text || text === '-') return null;
  return text;
}

function parseNullableNumber(value) {
  if (value === undefined || value === null) return null;

  const match = String(value)
    .replace(/,/g, '')
    .match(/-?\d+(?:\.\d+)?/);

  return match ? Number(match[0]) : null;
}

function absoluteUrl(url) {
  if (!url) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('//')) return `https:${url}`;
  if (url.startsWith('/')) return `https://www.ediya.com${url}`;
  return `https://www.ediya.com/${url}`;
}

function parseAllergyText(text) {
  const clean = normalizeText(text);
  if (!clean) return [];

  const raw = clean.includes(':')
    ? clean.split(':').slice(1).join(':').trim()
    : clean;

  return raw
    .split(/[,/]|·|ㆍ/)
    .map(v => v.trim())
    .filter(Boolean)
    .filter(v => v !== '없음' && v !== '-');
}

function extractSizeStandard(text) {
  const clean = normalizeText(text);
  if (!clean) return null;

  if (clean.includes(':')) {
    return normalizeText(clean.split(':').slice(1).join(':'));
  }

  return clean;
}

function parseEdiya(htmlContent) {
  const $ = cheerio.load(htmlContent);
  const menus = [];
  const seenNames = new Set();

  $('a[onclick^="show_nutri"]').each((i, link) => {
    const name =
      normalizeText($(link).find('span').text()) ||
      normalizeText($(link).text());

    if (!name || seenNames.has(name)) return;
    seenNames.add(name);

    const $li = $(link).closest('li');

    let imgUrl =
      $li.find('img').not('.pro_detail img').attr('src') ||
      $li.find('img[src$=".png"]').attr('src') ||
      $li.find('img').first().attr('src') ||
      null;

    imgUrl = absoluteUrl(imgUrl);

    const onClickAttr = $(link).attr('onclick') || '';
    const idMatch = onClickAttr.match(/'(\d+)'/);
    if (!idMatch) return;

    const targetId = `nutri_${idMatch[1]}`;
    const $detail = $(`#${targetId}`);
    if ($detail.length === 0) return;

    let sizeStandard = extractSizeStandard($detail.find('.pro_size').text());

    let calories = null;
    let sugar = null;
    let protein = null;
    let sodium = null;
    let saturatedFat = null;
    let caffeine = null;

    const extraNutrition = {};

    $detail.find('.pro_nutri dl').each((j, dl) => {
      const label = normalizeText($(dl).find('dt').text());
      const valueText = normalizeText($(dl).find('dd').text());

      if (!label || !valueText) return;

      const value = parseNullableNumber(valueText);

      if (label.includes('칼로리') || label.includes('열량')) {
        calories = value;
      } else if (label.includes('당류')) {
        sugar = value;
      } else if (label.includes('단백질')) {
        protein = value;
      } else if (label.includes('나트륨')) {
        sodium = value;
      } else if (label.includes('포화지방')) {
        saturatedFat = value;
      } else if (label.includes('카페인')) {
        caffeine = value;
      } else {
        extraNutrition[label] = value !== null ? value : valueText;
      }
    });

    const allergyInfo = parseAllergyText($detail.find('.pro_allergy').text());

    const descriptionParts = [];
    $detail.find('.detail_txt p').each((k, p) => {
      const txt = normalizeText($(p).text());
      if (txt) descriptionParts.push(txt);
    });

    const description =
      descriptionParts.length > 0 ? descriptionParts.join(' ') : null;

    const category = normalizeCategory('이디야커피', '음료', name);
    const menuType = category === '디저트' ? 'food' : 'beverage';

    const nutritionJson = {};
    if (Object.keys(extraNutrition).length > 0) {
      nutritionJson.extra_nutrition = extraNutrition;
    }

    menus.push({
      brand_name: '이디야커피',
      menu_name: name,
      category,
      description,
      size_standard: sizeStandard,
      image_url: imgUrl,
      is_active: true,
      menu_type: menuType,
      calories,
      sugar,
      protein,
      caffeine,
      saturated_fat: saturatedFat,
      sodium,
      nutrition_json: Object.keys(nutritionJson).length > 0 ? nutritionJson : null,
      allergy_info: allergyInfo,
    });
  });

  return menus;
}

module.exports = { parseEdiya };