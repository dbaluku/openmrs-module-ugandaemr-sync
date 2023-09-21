package org.openmrs.module.ugandaemrsync.page.controller;

import org.apache.commons.logging.LogFactory;
import org.openmrs.Patient;
import org.openmrs.PatientIdentifier;
import org.openmrs.PatientIdentifierType;
import org.openmrs.api.PatientService;
import org.openmrs.api.context.Context;
import org.openmrs.module.appui.UiSessionContext;
import org.openmrs.module.idgen.IdentifierSource;
import org.openmrs.module.idgen.service.IdentifierSourceService;
import org.openmrs.module.ugandaemrsync.api.UgandaEMRSyncService;
import org.openmrs.module.ugandaemrsync.model.SyncTask;
import org.openmrs.ui.framework.UiUtils;
import org.openmrs.ui.framework.annotation.SpringBean;
import org.openmrs.ui.framework.page.PageModel;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

public class SyncTaskPageController {

	protected final org.apache.commons.logging.Log log = LogFactory.getLog(SyncTaskPageController.class);

	public SyncTaskPageController() {
	}

	public void controller(@SpringBean PageModel pageModel,
						   @RequestParam(value = "breadcrumbOverride", required = false) String breadcrumbOverride,
						   UiSessionContext sessionContext, PageModel model, UiUtils ui) {
		UgandaEMRSyncService ugandaEMRSyncService = Context.getService(UgandaEMRSyncService.class);

		List<Patient> patientList = getPatientsWithoutOpenmrsID();
		patientList = patientList.stream().filter(patient -> !patient.getVoided()).collect(Collectors.toList());
		patientList = patientList.stream().filter(patient -> !patient.getDead()).collect(Collectors.toList());

		if (patientList.size() > 0) {
			for (Patient patient : patientList) {
				PatientIdentifier patientIdentifier = generatePatientIdentifier();
				patient.addIdentifier(patientIdentifier);
				Context.getPatientService().savePatient(patient);
				System.out.println("Openmrs ID added to patient ");
			}
		}

		List<SyncTask> syncTasks = ugandaEMRSyncService.getAllSyncTask();
		pageModel.put("syncTask", syncTasks);
		pageModel.put("breadcrumbOverride", breadcrumbOverride);
	}

	private List<Patient> getPatientsWithoutOpenmrsID() {
		String query =" Select p.patient_id from patient  p left join patient_identifier pi on p.patient_id = pi.patient_id and identifier_type=3 where identifier is null;\n";
		List list = Context.getAdministrationService().executeSQL(query, true);

		PatientService patientService = Context.getPatientService();
		List<Patient> patientList = new ArrayList<>();

		if (list.size() > 0) {
			for (Object o : list) {
				patientList.add(patientService.getPatient(Integer.parseUnsignedInt(((ArrayList) o).get(0).toString())));
			}
		}

		return patientList;
	}

	public PatientIdentifier generatePatientIdentifier() {
		IdentifierSourceService identifierSourceService = Context.getService(IdentifierSourceService.class);
		IdentifierSource idSource = identifierSourceService.getIdentifierSource(1);
		PatientService patientService = Context.getPatientService();

		UUID uuid = UUID.randomUUID();

		PatientIdentifierType patientIdentifierType = patientService.getPatientIdentifierTypeByUuid("05a29f94-c0ed-11e2-94be-8c13b969e334");

		PatientIdentifier patientIdentifier = new PatientIdentifier();
		patientIdentifier.setIdentifierType(patientIdentifierType);
		String identifier = identifierSourceService.generateIdentifier(idSource, "New OpenMRS ID with CheckDigit");
		patientIdentifier.setIdentifier(identifier);
		patientIdentifier.setPreferred(true);
		patientIdentifier.setUuid(String.valueOf(uuid));

		return patientIdentifier;
	}
}
