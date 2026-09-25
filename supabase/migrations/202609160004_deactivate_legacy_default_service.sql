-- The Clinician catalog is now authoritative. Preserve the legacy fallback row
-- for historical references but remove it from active patient selection.

begin;

update public.service_catalog
set is_active = false,
    updated_at = now()
where external_service_id = 'dawa-mom-general-consultation';

commit;
