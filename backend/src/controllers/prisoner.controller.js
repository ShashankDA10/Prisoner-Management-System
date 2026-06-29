const { validationResult } = require('express-validator');
const prisonerService = require('../services/prisoner.service');

class PrisonerController {
  getAll(req, res) {
    const { q, status, station } = req.query;
    const list = prisonerService.filter({ q, status, station });
    res.json({ data: list, total: list.length });
  }

  getStats(req, res) {
    res.json(prisonerService.getDashboardStats());
  }

  getByDateFilter(req, res) {
    const { filter = 'thisMonth', from, to } = req.query;
    const list = prisonerService.getByDateFilter(filter, from, to);
    res.json({ data: list, total: list.length });
  }

  getById(req, res) {
    const prisoner = prisonerService.getById(req.params.id);
    if (!prisoner) return res.status(404).json({ error: 'Prisoner not found' });
    res.json(prisoner);
  }

  create(req, res) {
    const errs = validationResult(req);
    if (!errs.isEmpty()) return res.status(400).json({ error: errs.array()[0].msg });

    const id = prisonerService.insert(req.body, req.user?.sub);
    const created = prisonerService.getById(id);
    res.status(201).json(created);
  }

  update(req, res) {
    const existing = prisonerService.getById(req.params.id);
    if (!existing) return res.status(404).json({ error: 'Prisoner not found' });

    prisonerService.update({ ...existing, ...req.body, id: req.params.id });
    res.json(prisonerService.getById(req.params.id));
  }

  delete(req, res) {
    const existing = prisonerService.getById(req.params.id);
    if (!existing) return res.status(404).json({ error: 'Prisoner not found' });

    prisonerService.delete(req.params.id);
    res.json({ message: 'Deleted successfully' });
  }

  bulkImport(req, res) {
    const { prisoners = [], updateExisting = false, skipDuplicates = true } = req.body;
    if (!Array.isArray(prisoners) || prisoners.length === 0) {
      return res.status(400).json({ error: 'No prisoners provided' });
    }
    const result = prisonerService.bulkImportModels(prisoners, { updateExisting, skipDuplicates });
    res.json({
      message: `Bulk import: ${result.inserted} inserted, ${result.updated} updated, ${result.skipped} skipped`,
      ...result,
    });
  }

  async importExcel(req, res) {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });

    const { updateExisting = false, skipDuplicates = true } = req.body;
    const result = await prisonerService.importExcel(req.file.buffer, {
      updateExisting: updateExisting === 'true' || updateExisting === true,
      skipDuplicates: skipDuplicates !== 'false' && skipDuplicates !== false,
    });

    res.json({
      message: `Import complete: ${result.inserted} inserted, ${result.updated} updated, ${result.skipped} skipped`,
      ...result,
    });
  }
}

module.exports = new PrisonerController();
