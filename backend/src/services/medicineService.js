const { query } = require('../config/database');
const { NotFoundError } = require('../utils/errors');
const cache = require('../config/redis');

class MedicineService {
  /**
   * Search medicines by keyword
   */
  async searchMedicines(keyword, page = 1, pageSize = 20) {
    const offset = (page - 1) * pageSize;

    // Full-text search with fallback to ILIKE
    const result = await query(
      `SELECT id, name, generic_name, category, dosage_form, specification, 
              manufacturer, barcode, plain_language_explanation
       FROM medicines
       WHERE is_active = TRUE
         AND (
           to_tsvector('simple', coalesce(name, '') || ' ' || coalesce(generic_name, '') || ' ' || coalesce(english_name, '')) @@ plainto_tsquery('simple', $1)
           OR name ILIKE $2
           OR generic_name ILIKE $2
         )
       ORDER BY 
         CASE WHEN name ILIKE $2 THEN 0 ELSE 1 END,
         name
       LIMIT $3 OFFSET $4`,
      [keyword, `%${keyword}%`, pageSize, offset]
    );

    // Count total results
    const countResult = await query(
      `SELECT COUNT(*) as total
       FROM medicines
       WHERE is_active = TRUE
         AND (
           to_tsvector('simple', coalesce(name, '') || ' ' || coalesce(generic_name, '') || ' ' || coalesce(english_name, '')) @@ plainto_tsquery('simple', $1)
           OR name ILIKE $2
           OR generic_name ILIKE $2
         )`,
      [keyword, `%${keyword}%`]
    );

    return {
      items: result.rows,
      total: parseInt(countResult.rows[0].total, 10),
      page,
      pageSize,
    };
  }

  /**
   * Get medicine by ID
   */
  async getMedicineById(id) {
    const cacheKey = `medicine:${id}`;
    const cached = await cache.getCache(cacheKey);
    if (cached) return cached;

    const result = await query(
      `SELECT * FROM medicines WHERE id = $1 AND is_active = TRUE`,
      [id]
    );

    if (result.rows.length === 0) {
      throw new NotFoundError('药品不存在');
    }

    const medicine = result.rows[0];
    await cache.setCache(cacheKey, medicine, 3600); // Cache for 1 hour
    return medicine;
  }

  /**
   * Get medicine by barcode
   */
  async getMedicineByBarcode(barcode) {
    const result = await query(
      `SELECT * FROM medicines WHERE barcode = $1 AND is_active = TRUE`,
      [barcode]
    );

    if (result.rows.length === 0) {
      throw new NotFoundError('未找到该条码对应的药品');
    }

    return result.rows[0];
  }

  /**
   * Check drug interactions
   */
  async checkInteractions(medicineIds) {
    if (medicineIds.length < 2) {
      return { interactions: [], summary: { total: 0, high: 0, medium: 0, low: 0 } };
    }

    // Build query for all pairs
    const placeholders = medicineIds.map((_, i) => `$${i + 1}`).join(', ');

    const result = await query(
      `SELECT 
         di.id,
         di.severity,
         di.severity_level,
         di.description,
         di.mechanism,
         di.clinical_management,
         di.symptoms,
         ma.id AS medicine_a_id,
         ma.name AS medicine_a_name,
         ma.generic_name AS medicine_a_generic,
         mb.id AS medicine_b_id,
         mb.name AS medicine_b_name,
         mb.generic_name AS medicine_b_generic
       FROM drug_interactions di
       JOIN medicines ma ON ma.id = di.medicine_a_id
       JOIN medicines mb ON mb.id = di.medicine_b_id
       WHERE (di.medicine_a_id IN (${placeholders}) AND di.medicine_b_id IN (${placeholders}))
       ORDER BY di.severity_level DESC`,
      [...medicineIds, ...medicineIds]
    );

    const interactions = result.rows;

    const summary = {
      total: interactions.length,
      high: interactions.filter((i) => i.severity === 'high').length,
      medium: interactions.filter((i) => i.severity === 'medium').length,
      low: interactions.filter((i) => i.severity === 'low').length,
    };

    return { interactions, summary };
  }

  /**
   * Get medicines by category
   */
  async getMedicinesByCategory(categoryCode, page = 1, pageSize = 20) {
    const offset = (page - 1) * pageSize;

    const result = await query(
      `SELECT id, name, generic_name, category, dosage_form, specification, manufacturer
       FROM medicines
       WHERE category_code = $1 AND is_active = TRUE
       ORDER BY name
       LIMIT $2 OFFSET $3`,
      [categoryCode, pageSize, offset]
    );

    const countResult = await query(
      `SELECT COUNT(*) as total FROM medicines WHERE category_code = $1 AND is_active = TRUE`,
      [categoryCode]
    );

    return {
      items: result.rows,
      total: parseInt(countResult.rows[0].total, 10),
      page,
      pageSize,
    };
  }
}

module.exports = new MedicineService();
