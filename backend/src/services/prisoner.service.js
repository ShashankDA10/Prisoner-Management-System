const prisonerRepo = require('../repositories/prisoner.repository');
const excelService = require('./excel.service');

class PrisonerService {
  getAll(station = null)          { return prisonerRepo.getAll(station); }
  getById(id)                     { return prisonerRepo.getById(id); }
  search(query, station = null)   { return prisonerRepo.search(query, station); }
  getByStatus(s, station = null)  { return prisonerRepo.getByStatus(s, station); }

  getDashboardStats(station = null) {
    return prisonerRepo.getDashboardStats(station);
  }

  getByDateFilter(filter, from, to, station = null) {
    return prisonerRepo.getByDateFilter(filter, from, to, station);
  }

  filter({ q, status, station } = {}) {
    let list = q?.trim()
      ? prisonerRepo.search(q.trim(), station)
      : prisonerRepo.getAll(station);
    if (status) list = list.filter(p => p.status === status);
    return list;
  }

  insert(model, userId) {
    return prisonerRepo.insert({ ...model, createdBy: userId });
  }

  update(model)  { return prisonerRepo.update(model); }
  delete(id)     { return prisonerRepo.delete(id); }

  searchCrossStation(query, excludeStation) {
    return prisonerRepo.searchCrossStation(query, excludeStation);
  }

  bulkImportModels(models, { updateExisting = false, skipDuplicates = true } = {}) {
    return prisonerRepo.bulkImport(models, { updateExisting, skipDuplicates });
  }

  async importExcel(buffer, { updateExisting = false, skipDuplicates = true, stationOverride = null } = {}) {
    const { models, errors } = excelService.parseExcel(buffer);
    const overridden = stationOverride
      ? models.map(m => ({ ...m, policeStation: stationOverride }))
      : models;
    const stats = prisonerRepo.bulkImport(overridden, { updateExisting, skipDuplicates });
    return { ...stats, parseErrors: errors };
  }
}

module.exports = new PrisonerService();
