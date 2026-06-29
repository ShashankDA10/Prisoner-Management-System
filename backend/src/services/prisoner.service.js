const prisonerRepo = require('../repositories/prisoner.repository');
const excelService = require('./excel.service');

class PrisonerService {
  getAll()          { return prisonerRepo.getAll(); }
  getById(id)       { return prisonerRepo.getById(id); }
  search(query)     { return prisonerRepo.search(query); }
  getByStatus(s)    { return prisonerRepo.getByStatus(s); }
  getDashboardStats() { return prisonerRepo.getDashboardStats(); }

  getByDateFilter(filter, from, to) {
    return prisonerRepo.getByDateFilter(filter, from, to);
  }

  /** Returns filtered list based on optional query params. */
  filter({ q, status, station } = {}) {
    let list = q?.trim() ? prisonerRepo.search(q.trim()) : prisonerRepo.getAll();
    if (status)  list = list.filter(p => p.status === status);
    if (station) list = list.filter(p =>
      p.policeStation.trim().toLowerCase() === station.trim().toLowerCase());
    return list;
  }

  insert(model, userId)  {
    return prisonerRepo.insert({ ...model, createdBy: userId });
  }

  update(model)    { return prisonerRepo.update(model); }
  delete(id)       { return prisonerRepo.delete(id); }

  /** Bulk import from pre-parsed JSON models (called from Flutter). */
  bulkImportModels(models, { updateExisting = false, skipDuplicates = true } = {}) {
    return prisonerRepo.bulkImport(models, { updateExisting, skipDuplicates });
  }

  /**
   * Parse Excel buffer and bulk-import.
   * Returns { inserted, updated, skipped, errors }.
   */
  async importExcel(buffer, { updateExisting = false, skipDuplicates = true } = {}) {
    const { models, errors } = excelService.parseExcel(buffer);
    const stats = prisonerRepo.bulkImport(models, { updateExisting, skipDuplicates });
    return { ...stats, parseErrors: errors };
  }
}

module.exports = new PrisonerService();
