const { validationResult } = require('express-validator');
const prisonerService = require('../services/prisoner.service');

class PrisonerController {
  getAll(req, res) {
    const { q, status } = req.query;
    // Station-locked users: scope enforced from JWT; admins: optional ?station= drill-down
    const station = req.stationScope ?? req.query.station;
    const list = prisonerService.filter({ q, status, station });
    res.json({ data: list, total: list.length });
  }

  getStats(req, res) {
    res.json(prisonerService.getDashboardStats(req.stationScope));
  }

  getByDateFilter(req, res) {
    const { filter = 'thisMonth', from, to } = req.query;
    const list = prisonerService.getByDateFilter(filter, from, to, req.stationScope);
    res.json({ data: list, total: list.length });
  }

  getById(req, res) {
    const prisoner = prisonerService.getById(req.params.id);
    if (!prisoner) return res.status(404).json({ error: 'Prisoner not found' });

    if (req.stationScope &&
        prisoner.policeStation.trim().toLowerCase() !== req.stationScope.trim().toLowerCase()) {
      return res.status(403).json({ error: 'Access denied: prisoner belongs to another station' });
    }
    res.json(prisoner);
  }

  create(req, res) {
    const errs = validationResult(req);
    if (!errs.isEmpty()) return res.status(400).json({ error: errs.array()[0].msg });

    const data = { ...req.body };
    // Override policeStation from JWT — station-locked users cannot self-assign a different station
    if (req.stationScope) data.policeStation = req.stationScope;

    const id = prisonerService.insert(data, req.user.sub);
    res.status(201).json(prisonerService.getById(id));
  }

  update(req, res) {
    const existing = prisonerService.getById(req.params.id);
    if (!existing) return res.status(404).json({ error: 'Prisoner not found' });

    if (req.stationScope &&
        existing.policeStation.trim().toLowerCase() !== req.stationScope.trim().toLowerCase()) {
      return res.status(403).json({ error: 'Access denied: cannot modify records from another station' });
    }

    const data = { ...existing, ...req.body, id: req.params.id };
    // Prevent policeStation from being changed by a station-locked user
    if (req.stationScope) data.policeStation = req.stationScope;

    prisonerService.update(data);
    res.json(prisonerService.getById(req.params.id));
  }

  delete(req, res) {
    const existing = prisonerService.getById(req.params.id);
    if (!existing) return res.status(404).json({ error: 'Prisoner not found' });

    if (req.stationScope &&
        existing.policeStation.trim().toLowerCase() !== req.stationScope.trim().toLowerCase()) {
      return res.status(403).json({ error: 'Access denied: cannot delete records from another station' });
    }

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

  getCrossStation(req, res) {
    const { q, excludeStation } = req.query;
    // Station-locked users: always exclude their own station (from JWT, not query)
    // Admins: respect the optional ?excludeStation= param
    const exclude = req.stationScope ?? excludeStation ?? null;
    const list = prisonerService.searchCrossStation(q?.trim() || '', exclude);
    res.json({ data: list, total: list.length });
  }
}

module.exports = new PrisonerController();
