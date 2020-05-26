BEGIN;

CREATE TYPE bookbrainz.lang_proficiency AS ENUM (
	'BASIC',
	'INTERMEDIATE',
	'ADVANCED',
	'NATIVE'
);

CREATE TYPE bookbrainz.entity_type AS ENUM (
	'Author',
	'EditionGroup',
	'Edition',
	'Publisher',
	'Work'
);

CREATE TABLE bookbrainz.editor_type (
	id SERIAL PRIMARY KEY,
	label VARCHAR(255) NOT NULL CHECK (label <> '')
);

CREATE TABLE bookbrainz.editor (
	id SERIAL PRIMARY KEY,
	name VARCHAR(64) NOT NULL UNIQUE CHECK (name <> ''),
	metabrainz_user_id INTEGER CHECK (metabrainz_user_id >= 0),
	cached_metabrainz_name VARCHAR(64),
	reputation INT NOT NULL DEFAULT 0,
	bio TEXT NOT NULL DEFAULT '',
	created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT timezone('UTC'::TEXT, now()),
	active_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT timezone('UTC'::TEXT, now()),
	type_id INT NOT NULL,
	gender_id INT,
	area_id INT,
	revisions_applied INT NOT NULL DEFAULT 0 CHECK (revisions_applied >= 0),
	revisions_reverted INT NOT NULL DEFAULT 0 CHECK (revisions_reverted >= 0),
	total_revisions INT NOT NULL DEFAULT 0 CHECK (total_revisions >= 0),
	title_unlock_id INT
);
ALTER TABLE bookbrainz.editor ADD FOREIGN KEY (gender_id) REFERENCES musicbrainz.gender (id) DEFERRABLE;
ALTER TABLE bookbrainz.editor ADD FOREIGN KEY (type_id) REFERENCES bookbrainz.editor_type (id);
ALTER TABLE bookbrainz.editor ADD FOREIGN KEY (area_id) REFERENCES musicbrainz.area (id) DEFERRABLE;

CREATE TABLE bookbrainz.editor__language (
	editor_id INT,
	language_id INT,
	proficiency bookbrainz.lang_proficiency NOT NULL,
	PRIMARY KEY (
		editor_id,
		language_id
	)
);

CREATE TABLE bookbrainz.entity (
	bbid UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),
	type bookbrainz.entity_type NOT NULL
);
ALTER TABLE bookbrainz.entity ADD FOREIGN KEY (bbid) REFERENCES bookbrainz.entity (bbid);

CREATE TABLE bookbrainz.entity_redirect (
	source_bbid UUID,
	target_bbid UUID,
	PRIMARY KEY (
		source_bbid,
		target_bbid
	)
);
ALTER TABLE bookbrainz.entity_redirect ADD FOREIGN KEY (source_bbid) REFERENCES bookbrainz.entity (bbid);
ALTER TABLE bookbrainz.entity_redirect ADD FOREIGN KEY (target_bbid) REFERENCES bookbrainz.entity (bbid);

CREATE TABLE bookbrainz.author_header (
	bbid UUID PRIMARY KEY,
	master_revision_id INT
);
ALTER TABLE bookbrainz.author_header ADD FOREIGN KEY (bbid) REFERENCES bookbrainz.entity (bbid);

CREATE TABLE bookbrainz.edition_group_header (
	bbid UUID PRIMARY KEY,
	master_revision_id INT
);
ALTER TABLE bookbrainz.edition_group_header ADD FOREIGN KEY (bbid) REFERENCES bookbrainz.entity (bbid);

CREATE TABLE bookbrainz.edition_header (
	bbid UUID PRIMARY KEY,
	master_revision_id INT
);
ALTER TABLE bookbrainz.edition_header ADD FOREIGN KEY (bbid) REFERENCES bookbrainz.entity (bbid);

CREATE TABLE bookbrainz.publisher_header (
	bbid UUID PRIMARY KEY,
	master_revision_id INT
);
ALTER TABLE bookbrainz.publisher_header ADD FOREIGN KEY (bbid) REFERENCES bookbrainz.entity (bbid);

CREATE TABLE bookbrainz.work_header (
	bbid UUID PRIMARY KEY,
	master_revision_id INT
);
ALTER TABLE bookbrainz.work_header ADD FOREIGN KEY (bbid) REFERENCES bookbrainz.entity (bbid);

CREATE TABLE bookbrainz.revision_parent (
	parent_id INT,
	child_id INT,
	PRIMARY KEY(
		parent_id,
		child_id
	)
);

CREATE TABLE bookbrainz.revision (
	id SERIAL PRIMARY KEY,
	author_id INT NOT NULL,
	created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT timezone('UTC'::TEXT, now()),
	is_merge BOOLEAN NOT NULL DEFAULT FALSE
);
ALTER TABLE bookbrainz.revision ADD FOREIGN KEY (author_id) REFERENCES bookbrainz.editor (id);
ALTER TABLE bookbrainz.revision_parent ADD FOREIGN KEY (parent_id) REFERENCES bookbrainz.revision (id);
ALTER TABLE bookbrainz.revision_parent ADD FOREIGN KEY (child_id) REFERENCES bookbrainz.revision (id);

CREATE TABLE bookbrainz.author_revision (
	id INT,
	bbid UUID,
	data_id INT,
	is_merge BOOLEAN NOT NULL DEFAULT FALSE,
	PRIMARY KEY (
		id, bbid
	)
);
ALTER TABLE bookbrainz.author_revision ADD FOREIGN KEY (id) REFERENCES bookbrainz.revision (id);
ALTER TABLE bookbrainz.author_revision ADD FOREIGN KEY (bbid) REFERENCES bookbrainz.author_header (bbid);
ALTER TABLE bookbrainz.author_header ADD FOREIGN KEY (master_revision_id, bbid) REFERENCES bookbrainz.author_revision (id, bbid);

CREATE TABLE bookbrainz.edition_group_revision (
	id INT,
	bbid UUID,
	data_id INT,
	is_merge BOOLEAN NOT NULL DEFAULT FALSE,
	PRIMARY KEY (
		id, bbid
	)
);
ALTER TABLE bookbrainz.edition_group_revision ADD FOREIGN KEY (id) REFERENCES bookbrainz.revision (id);
ALTER TABLE bookbrainz.edition_group_revision ADD FOREIGN KEY (bbid) REFERENCES bookbrainz.edition_group_header (bbid);
ALTER TABLE bookbrainz.edition_group_header ADD FOREIGN KEY (master_revision_id, bbid) REFERENCES bookbrainz.edition_group_revision (id, bbid);

CREATE TABLE bookbrainz.edition_revision (
	id INT,
	bbid UUID,
	data_id INT,
	is_merge BOOLEAN NOT NULL DEFAULT FALSE,
	PRIMARY KEY (
		id, bbid
	)
);
ALTER TABLE bookbrainz.edition_revision ADD FOREIGN KEY (id) REFERENCES bookbrainz.revision (id);
ALTER TABLE bookbrainz.edition_revision ADD FOREIGN KEY (bbid) REFERENCES bookbrainz.edition_header (bbid);
ALTER TABLE bookbrainz.edition_header ADD FOREIGN KEY (master_revision_id, bbid) REFERENCES bookbrainz.edition_revision (id, bbid);

CREATE TABLE bookbrainz.publisher_revision (
	id INT,
	bbid UUID,
	data_id INT,
	is_merge BOOLEAN NOT NULL DEFAULT FALSE,
	PRIMARY KEY (
		id, bbid
	)
);
ALTER TABLE bookbrainz.publisher_revision ADD FOREIGN KEY (id) REFERENCES bookbrainz.revision (id);
ALTER TABLE bookbrainz.publisher_revision ADD FOREIGN KEY (bbid) REFERENCES bookbrainz.publisher_header (bbid);
ALTER TABLE bookbrainz.publisher_header ADD FOREIGN KEY (master_revision_id, bbid) REFERENCES bookbrainz.publisher_revision (id, bbid);

CREATE TABLE bookbrainz.work_revision (
	id INT,
	bbid UUID,
	data_id INT,
	is_merge BOOLEAN NOT NULL DEFAULT FALSE,
	PRIMARY KEY (
		id, bbid
	)
);
ALTER TABLE bookbrainz.work_revision ADD FOREIGN KEY (id) REFERENCES bookbrainz.revision (id);
ALTER TABLE bookbrainz.work_revision ADD FOREIGN KEY (bbid) REFERENCES bookbrainz.work_header (bbid);
ALTER TABLE bookbrainz.work_header ADD FOREIGN KEY (master_revision_id, bbid) REFERENCES bookbrainz.work_revision (id, bbid);

CREATE TABLE bookbrainz.note (
	id SERIAL PRIMARY KEY,
	author_id INT NOT NULL,
	revision_id INT NOT NULL,
	content TEXT NOT NULL CHECK (content <> ''),
	posted_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT timezone('UTC'::TEXT, now())
);
ALTER TABLE bookbrainz.note ADD FOREIGN KEY (author_id) REFERENCES bookbrainz.editor (id);
ALTER TABLE bookbrainz.note ADD FOREIGN KEY (revision_id) REFERENCES bookbrainz.revision (id);

CREATE TABLE bookbrainz.author_type (
	id SERIAL PRIMARY KEY,
	label TEXT NOT NULL UNIQUE CHECK (label <> '')
);

CREATE TABLE bookbrainz.author_data (
	id SERIAL PRIMARY KEY,
	alias_set_id INT NOT NULL,
	identifier_set_id INT,
	relationship_set_id INT,
	annotation_id INT,
	disambiguation_id INT,
	begin_year SMALLINT,
	begin_month SMALLINT,
	begin_day SMALLINT,
	begin_area_id INT,
	end_year SMALLINT,
	end_month SMALLINT,
	end_day SMALLINT,
	end_area_id INT,
	ended BOOLEAN NOT NULL DEFAULT FALSE,
	area_id INT,
	gender_id INT,
	type_id INT,
	CHECK (
		(
			-- If any end date fields are not null, then ended must be true
			(
				end_year IS NOT NULL OR
				end_month IS NOT NULL OR
				end_day IS NOT NULL
			) AND ended = TRUE
		) OR (
			-- Otherwise, all end date fields must be null
			(
				end_year IS NULL AND
				end_month IS NULL AND
				end_day IS NULL
			)
		)
	)
);
ALTER TABLE bookbrainz.author_data ADD FOREIGN KEY (gender_id) REFERENCES musicbrainz.gender (id) DEFERRABLE;
ALTER TABLE bookbrainz.author_data ADD FOREIGN KEY (type_id) REFERENCES bookbrainz.author_type (id);
ALTER TABLE bookbrainz.author_data ADD FOREIGN KEY (area_id) REFERENCES musicbrainz.area (id) DEFERRABLE;
ALTER TABLE bookbrainz.author_data ADD FOREIGN KEY (begin_area_id) REFERENCES musicbrainz.area (id) DEFERRABLE;
ALTER TABLE bookbrainz.author_data ADD FOREIGN KEY (end_area_id) REFERENCES musicbrainz.area (id) DEFERRABLE;
ALTER TABLE bookbrainz.author_revision ADD FOREIGN KEY (data_id) REFERENCES bookbrainz.author_data (id);

CREATE TABLE bookbrainz.release_event (
	id SERIAL PRIMARY KEY,
	"year" SMALLINT,
	"month" SMALLINT,
	"day" SMALLINT,
	area_id INT
);
ALTER TABLE bookbrainz.release_event ADD FOREIGN KEY (area_id) REFERENCES musicbrainz.country_area (area) DEFERRABLE;

CREATE TABLE bookbrainz.release_event_set (
	id SERIAL PRIMARY KEY
);

CREATE TABLE bookbrainz.release_event_set__release_event (
	set_id INT,
	release_event_id INT,
	PRIMARY KEY (
		set_id,
		release_event_id
	)
);
ALTER TABLE bookbrainz.release_event_set__release_event ADD FOREIGN KEY (set_id) REFERENCES bookbrainz.release_event_set (id);
ALTER TABLE bookbrainz.release_event_set__release_event ADD FOREIGN KEY (release_event_id) REFERENCES bookbrainz.release_event (id);

CREATE TABLE bookbrainz.author_credit (
	id SERIAL PRIMARY KEY,
	author_count SMALLINT NOT NULL,
	ref_count INT NOT NULL DEFAULT 0
);

CREATE TABLE bookbrainz.author_credit_name (
	author_credit_id INT,
	"position" SMALLINT NOT NULL CHECK ("position" >= 0),
	author_bbid UUID NOT NULL,
	name VARCHAR NOT NULL CHECK (name <> ''),
	join_phrase TEXT NOT NULL,
	PRIMARY KEY (
		author_credit_id,
		position
	)
);
ALTER TABLE bookbrainz.author_credit_name ADD FOREIGN KEY (author_credit_id) REFERENCES bookbrainz.author_credit (id);
ALTER TABLE bookbrainz.author_credit_name ADD FOREIGN KEY (author_bbid) REFERENCES bookbrainz.author_header (bbid);

CREATE TABLE bookbrainz.publisher_set (
	id SERIAL PRIMARY KEY
);

CREATE TABLE bookbrainz.publisher_set__publisher (
	set_id INT,
	publisher_bbid UUID,
	PRIMARY KEY (
		set_id,
		publisher_bbid
	)
);
ALTER TABLE bookbrainz.publisher_set__publisher ADD FOREIGN KEY (set_id) REFERENCES bookbrainz.publisher_set (id);
ALTER TABLE bookbrainz.publisher_set__publisher ADD FOREIGN KEY (publisher_bbid) REFERENCES bookbrainz.publisher_header (bbid);

CREATE TABLE bookbrainz.edition_format (
	id SERIAL PRIMARY KEY,
	label TEXT NOT NULL UNIQUE CHECK (label <> '')
);

CREATE TABLE bookbrainz.edition_status (
	id SERIAL PRIMARY KEY,
	label TEXT NOT NULL UNIQUE CHECK (label <> '')
);

CREATE TABLE bookbrainz.edition_data (
	id SERIAL PRIMARY KEY,
	alias_set_id INT NOT NULL,
	identifier_set_id INT,
	relationship_set_id INT,
	annotation_id INT,
	disambiguation_id INT,
	edition_group_bbid UUID,
	author_credit_id INT,
	publisher_set_id INT,
	language_set_id INT,
	release_event_set_id INT,
	width SMALLINT CHECK (width >= 0),
	height SMALLINT CHECK (height >= 0),
	depth SMALLINT CHECK (depth >= 0),
	weight SMALLINT CHECK (weight >= 0),
	pages SMALLINT CHECK (pages >= 0),
	format_id INT,
	status_id INT
);
ALTER TABLE bookbrainz.edition_data ADD FOREIGN KEY (author_credit_id) REFERENCES bookbrainz.author_credit (id);
ALTER TABLE bookbrainz.edition_data ADD FOREIGN KEY (format_id) REFERENCES bookbrainz.edition_format (id);
ALTER TABLE bookbrainz.edition_data ADD FOREIGN KEY (edition_group_bbid) REFERENCES bookbrainz.edition_group_header (bbid);
ALTER TABLE bookbrainz.edition_data ADD FOREIGN KEY (status_id) REFERENCES bookbrainz.edition_status (id);
ALTER TABLE bookbrainz.edition_data ADD FOREIGN KEY (publisher_set_id) REFERENCES bookbrainz.publisher_set (id);
ALTER TABLE bookbrainz.edition_data ADD FOREIGN KEY (release_event_set_id) REFERENCES bookbrainz.release_event_set (id);
ALTER TABLE bookbrainz.edition_revision ADD FOREIGN KEY (data_id) REFERENCES bookbrainz.edition_data (id);

CREATE TABLE bookbrainz.edition_group_type (
	id SERIAL PRIMARY KEY,
	label TEXT NOT NULL UNIQUE CHECK (label <> '')
);

CREATE TABLE bookbrainz.edition_group_data (
	id SERIAL PRIMARY KEY,
	alias_set_id INT NOT NULL,
	identifier_set_id INT,
	relationship_set_id INT,
	annotation_id INT,
	disambiguation_id INT,
	author_credit_id INT,
	type_id INT
);
ALTER TABLE bookbrainz.edition_group_data ADD FOREIGN KEY (type_id) REFERENCES bookbrainz.edition_group_type (id);
ALTER TABLE bookbrainz.edition_group_data ADD FOREIGN KEY (author_credit_id) REFERENCES bookbrainz.author_credit (id);
ALTER TABLE bookbrainz.edition_group_revision ADD FOREIGN KEY (data_id) REFERENCES bookbrainz.edition_group_data (id);

CREATE TABLE bookbrainz.publisher_type (
	id SERIAL PRIMARY KEY,
	label TEXT NOT NULL UNIQUE CHECK (label <> '')
);

CREATE TABLE bookbrainz.publisher_data (
	id SERIAL PRIMARY KEY,
	alias_set_id INT NOT NULL,
	identifier_set_id INT,
	relationship_set_id INT,
	annotation_id INT,
	disambiguation_id INT,
	begin_year SMALLINT,
	begin_month SMALLINT,
	begin_day SMALLINT,
	end_year SMALLINT,
	end_month SMALLINT,
	end_day SMALLINT,
	ended BOOLEAN NOT NULL DEFAULT FALSE,
	area_id INT,
	type_id INT,
	CHECK (
		(
			-- If any end date fields are not null, then ended must be true
			(
				end_year IS NOT NULL OR
				end_month IS NOT NULL OR
				end_day IS NOT NULL
			) AND ended = TRUE
		) OR (
			-- Otherwise, all end date fields must be null
			(
				end_year IS NULL AND
				end_month IS NULL AND
				end_day IS NULL
			)
		)
	)
);
ALTER TABLE bookbrainz.publisher_data ADD FOREIGN KEY (type_id) REFERENCES bookbrainz.publisher_type (id);
ALTER TABLE bookbrainz.publisher_data ADD FOREIGN KEY (area_id) REFERENCES musicbrainz.area (id) DEFERRABLE;
ALTER TABLE bookbrainz.publisher_revision ADD FOREIGN KEY (data_id) REFERENCES bookbrainz.publisher_data (id);

CREATE TABLE bookbrainz.work_type (
	id SERIAL PRIMARY KEY,
	label TEXT NOT NULL UNIQUE CHECK (label <> '')
);

CREATE TABLE bookbrainz.work_data (
	id SERIAL PRIMARY KEY,
	alias_set_id INT NOT NULL,
	identifier_set_id INT,
	relationship_set_id INT,
	annotation_id INT,
	disambiguation_id INT,
	language_set_id INT,
	type_id INT
);
ALTER TABLE bookbrainz.work_data ADD FOREIGN KEY (type_id) REFERENCES bookbrainz.work_type (id);
ALTER TABLE bookbrainz.work_revision ADD FOREIGN KEY (data_id) REFERENCES bookbrainz.work_data (id);

CREATE TABLE bookbrainz.annotation (
	id SERIAL PRIMARY KEY,
	content TEXT NOT NULL,
	last_revision_id INT NOT NULL
);
ALTER TABLE bookbrainz.annotation ADD FOREIGN KEY (last_revision_id) REFERENCES bookbrainz.revision (id);
ALTER TABLE bookbrainz.author_data ADD FOREIGN KEY (annotation_id) REFERENCES bookbrainz.annotation (id);
ALTER TABLE bookbrainz.edition_data ADD FOREIGN KEY (annotation_id) REFERENCES bookbrainz.annotation (id);
ALTER TABLE bookbrainz.edition_group_data ADD FOREIGN KEY (annotation_id) REFERENCES bookbrainz.annotation (id);
ALTER TABLE bookbrainz.publisher_data ADD FOREIGN KEY (annotation_id) REFERENCES bookbrainz.annotation (id);
ALTER TABLE bookbrainz.work_data ADD FOREIGN KEY (annotation_id) REFERENCES bookbrainz.annotation (id);

CREATE TABLE bookbrainz.disambiguation (
	id SERIAL PRIMARY KEY,
	comment TEXT NOT NULL
);
ALTER TABLE bookbrainz.author_data ADD FOREIGN KEY (disambiguation_id) REFERENCES bookbrainz.disambiguation (id);
ALTER TABLE bookbrainz.edition_data ADD FOREIGN KEY (disambiguation_id) REFERENCES bookbrainz.disambiguation (id);
ALTER TABLE bookbrainz.edition_group_data ADD FOREIGN KEY (disambiguation_id) REFERENCES bookbrainz.disambiguation (id);
ALTER TABLE bookbrainz.publisher_data ADD FOREIGN KEY (disambiguation_id) REFERENCES bookbrainz.disambiguation (id);
ALTER TABLE bookbrainz.work_data ADD FOREIGN KEY (disambiguation_id) REFERENCES bookbrainz.disambiguation (id);

CREATE TABLE bookbrainz.alias (
	id SERIAL PRIMARY KEY,
	name TEXT NOT NULL CHECK (name <> ''),
	sort_name TEXT NOT NULL CHECK (sort_name <> ''),
	language_id INT,
	"primary" BOOLEAN NOT NULL DEFAULT FALSE
);
ALTER TABLE bookbrainz.alias ADD FOREIGN KEY (language_id) REFERENCES musicbrainz.language (id) DEFERRABLE;

CREATE TABLE bookbrainz.identifier_type (
	id SERIAL PRIMARY KEY,
	label VARCHAR(255) NOT NULL CHECK (label <> ''),
	description TEXT NOT NULL CHECK (description <> ''),
	detection_regex TEXT,
	validation_regex TEXT NOT NULL,
	display_template TEXT NOT NULL CHECK (display_template <> ''),
	entity_type bookbrainz.entity_type NOT NULL,
	parent_id INT,
	child_order INT NOT NULL DEFAULT 0,
	deprecated BOOLEAN NOT NULL DEFAULT FALSE
);
ALTER TABLE bookbrainz.identifier_type ADD FOREIGN KEY (parent_id) REFERENCES bookbrainz.identifier_type (id);

CREATE TABLE bookbrainz.identifier (
	id SERIAL PRIMARY KEY,
	type_id INT NOT NULL,
	value TEXT NOT NULL CHECK (value <> '')
);
ALTER TABLE bookbrainz.identifier ADD FOREIGN KEY (type_id) REFERENCES bookbrainz.identifier_type (id);

CREATE TABLE bookbrainz.relationship_type (
	id SERIAL PRIMARY KEY,
	label VARCHAR(255) NOT NULL CHECK (label <> ''),
	description TEXT NOT NULL CHECK (description <> ''),
	link_phrase TEXT NOT NULL CHECK (link_phrase <> ''),
	reverse_link_phrase TEXT NOT NULL CHECK (reverse_link_phrase <> ''),
	source_entity_type bookbrainz.entity_type NOT NULL,
	target_entity_type bookbrainz.entity_type NOT NULL,
	parent_id INT,
	child_order INT NOT NULL DEFAULT 0,
	deprecated BOOLEAN NOT NULL DEFAULT FALSE
);
ALTER TABLE bookbrainz.relationship_type ADD FOREIGN KEY (parent_id) REFERENCES bookbrainz.relationship_type (id);

CREATE TABLE bookbrainz.alias_set (
	id SERIAL PRIMARY KEY,
	default_alias_id INT
);
ALTER TABLE bookbrainz.author_data ADD FOREIGN KEY (alias_set_id) REFERENCES bookbrainz.alias_set (id);
ALTER TABLE bookbrainz.edition_data ADD FOREIGN KEY (alias_set_id) REFERENCES bookbrainz.alias_set (id);
ALTER TABLE bookbrainz.edition_group_data ADD FOREIGN KEY (alias_set_id) REFERENCES bookbrainz.alias_set (id);
ALTER TABLE bookbrainz.publisher_data ADD FOREIGN KEY (alias_set_id) REFERENCES bookbrainz.alias_set (id);
ALTER TABLE bookbrainz.work_data ADD FOREIGN KEY (alias_set_id) REFERENCES bookbrainz.alias_set (id);
ALTER TABLE bookbrainz.alias_set ADD FOREIGN KEY (default_alias_id) REFERENCES bookbrainz.alias (id);

CREATE TABLE bookbrainz.alias_set__alias (
	set_id INT,
	alias_id INT,
	PRIMARY KEY (
		set_id,
		alias_id
	)
);
ALTER TABLE bookbrainz.alias_set__alias ADD FOREIGN KEY (set_id) REFERENCES bookbrainz.alias_set (id);
ALTER TABLE bookbrainz.alias_set__alias ADD FOREIGN KEY (alias_id) REFERENCES bookbrainz.alias (id);

CREATE TABLE bookbrainz.identifier_set (
	id SERIAL PRIMARY KEY
);
ALTER TABLE bookbrainz.author_data ADD FOREIGN KEY (identifier_set_id) REFERENCES bookbrainz.identifier_set (id);
ALTER TABLE bookbrainz.edition_data ADD FOREIGN KEY (identifier_set_id) REFERENCES bookbrainz.identifier_set (id);
ALTER TABLE bookbrainz.edition_group_data ADD FOREIGN KEY (identifier_set_id) REFERENCES bookbrainz.identifier_set (id);
ALTER TABLE bookbrainz.publisher_data ADD FOREIGN KEY (identifier_set_id) REFERENCES bookbrainz.identifier_set (id);
ALTER TABLE bookbrainz.work_data ADD FOREIGN KEY (identifier_set_id) REFERENCES bookbrainz.identifier_set (id);

CREATE TABLE bookbrainz.identifier_set__identifier (
	set_id INT,
	identifier_id INT,
	PRIMARY KEY (
		set_id,
		identifier_id
	)
);
ALTER TABLE bookbrainz.identifier_set__identifier ADD FOREIGN KEY (set_id) REFERENCES bookbrainz.identifier_set (id);
ALTER TABLE bookbrainz.identifier_set__identifier ADD FOREIGN KEY (identifier_id) REFERENCES bookbrainz.identifier (id);

CREATE TABLE bookbrainz.relationship_set (
	id SERIAL PRIMARY KEY
);
ALTER TABLE bookbrainz.author_data ADD FOREIGN KEY (relationship_set_id) REFERENCES bookbrainz.relationship_set (id);
ALTER TABLE bookbrainz.edition_data ADD FOREIGN KEY (relationship_set_id) REFERENCES bookbrainz.relationship_set (id);
ALTER TABLE bookbrainz.edition_group_data ADD FOREIGN KEY (relationship_set_id) REFERENCES bookbrainz.relationship_set (id);
ALTER TABLE bookbrainz.publisher_data ADD FOREIGN KEY (relationship_set_id) REFERENCES bookbrainz.relationship_set (id);
ALTER TABLE bookbrainz.work_data ADD FOREIGN KEY (relationship_set_id) REFERENCES bookbrainz.relationship_set (id);

CREATE TABLE bookbrainz.relationship_set__relationship (
	set_id INTEGER,
	relationship_id INTEGER,
	PRIMARY KEY (
		set_id,
		relationship_id
	)
);
ALTER TABLE bookbrainz.relationship_set__relationship ADD FOREIGN KEY (set_id) REFERENCES bookbrainz.relationship_set (id);

CREATE TABLE bookbrainz.relationship (
	id SERIAL PRIMARY KEY,
	type_id INT NOT NULL,
	source_bbid UUID NOT NULL,
	target_bbid UUID NOT NULL
);
ALTER TABLE bookbrainz.relationship_set__relationship ADD FOREIGN KEY (relationship_id) REFERENCES bookbrainz.relationship (id);
ALTER TABLE bookbrainz.relationship ADD FOREIGN KEY (type_id) REFERENCES bookbrainz.relationship_type (id);
ALTER TABLE bookbrainz.relationship ADD FOREIGN KEY (source_bbid) REFERENCES bookbrainz.entity (bbid);
ALTER TABLE bookbrainz.relationship ADD FOREIGN KEY (target_bbid) REFERENCES bookbrainz.entity (bbid);

CREATE TABLE bookbrainz.language_set (
	id SERIAL PRIMARY KEY
);

CREATE TABLE bookbrainz.language_set__language (
	set_id INT,
	language_id INT,
	PRIMARY KEY (
		set_id,
		language_id
	)
);
ALTER TABLE bookbrainz.language_set__language ADD FOREIGN KEY (set_id) REFERENCES bookbrainz.language_set (id);
ALTER TABLE bookbrainz.language_set__language ADD FOREIGN KEY (language_id) REFERENCES musicbrainz.language (id) DEFERRABLE;

ALTER TABLE bookbrainz.edition_data ADD FOREIGN KEY (language_set_id) REFERENCES bookbrainz.language_set (id);
ALTER TABLE bookbrainz.work_data ADD FOREIGN KEY (language_set_id) REFERENCES bookbrainz.language_set (id);

CREATE TABLE bookbrainz.title_type (
	id SERIAL PRIMARY KEY,
	title VARCHAR(40) NOT NULL CHECK (title <> ''),
	description TEXT NOT NULL CHECK (description <> '')
);

CREATE TABLE bookbrainz.title_unlock (
	id SERIAL PRIMARY KEY,
	editor_id INT NOT NULL,
	title_id INT NOT NULL,
	unlocked_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT timezone('UTC'::TEXT, now())
);
ALTER TABLE bookbrainz.title_unlock ADD FOREIGN KEY (editor_id) REFERENCES bookbrainz.editor (id);
ALTER TABLE bookbrainz.title_unlock ADD FOREIGN KEY (title_id) REFERENCES bookbrainz.title_type (id);
ALTER TABLE bookbrainz.editor ADD FOREIGN KEY (title_unlock_id) REFERENCES bookbrainz.title_unlock (id);

CREATE TABLE bookbrainz.achievement_type (
	id SERIAL PRIMARY KEY,
	name VARCHAR(80) NOT NULL CHECK (name <> ''),
	description TEXT NOT NULL CHECK (description <> ''),
	badge_url VARCHAR(2000)
);
CREATE TABLE bookbrainz.achievement_unlock (
	id SERIAL PRIMARY KEY,
	editor_id INT NOT NULL,
	achievement_id INT NOT NULL,
	unlocked_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT timezone('UTC'::TEXT, now()),
	profile_rank SMALLINT
);
ALTER TABLE bookbrainz.achievement_unlock ADD FOREIGN KEY (editor_id) REFERENCES bookbrainz.editor (id);
ALTER TABLE bookbrainz.achievement_unlock ADD FOREIGN KEY (achievement_id) REFERENCES bookbrainz.achievement_type (id);

CREATE TABLE bookbrainz._editor_entity_visits (
	id SERIAL PRIMARY KEY,
	editor_id INT NOT NULL,
	bbid UUID NOT NULL,
	UNIQUE (editor_id, bbid)
);

ALTER TABLE bookbrainz._editor_entity_visits ADD FOREIGN KEY (editor_id) REFERENCES bookbrainz.editor (id);
ALTER TABLE bookbrainz._editor_entity_visits ADD FOREIGN KEY (bbid) REFERENCES bookbrainz.entity (bbid);

CREATE TABLE IF NOT EXISTS bookbrainz.import (
	id SERIAL PRIMARY KEY,
	type bookbrainz.entity_type NOT NULL
);

CREATE TABLE IF NOT EXISTS bookbrainz.author_import_header (
	import_id INT PRIMARY KEY,
	data_id INT NOT NULL
);
ALTER TABLE bookbrainz.author_import_header ADD FOREIGN KEY (import_id) REFERENCES bookbrainz.import (id);
ALTER TABLE bookbrainz.author_import_header ADD FOREIGN KEY (data_id) REFERENCES bookbrainz.author_data (id);

CREATE TABLE IF NOT EXISTS bookbrainz.edition_import_header (
	import_id INT PRIMARY KEY,
	data_id INT NOT NULL
);
ALTER TABLE bookbrainz.edition_import_header ADD FOREIGN KEY (import_id) REFERENCES bookbrainz.import (id);
ALTER TABLE bookbrainz.edition_import_header ADD FOREIGN KEY (data_id) REFERENCES bookbrainz.edition_data (id);

CREATE TABLE IF NOT EXISTS bookbrainz.edition_group_import_header (
	import_id INT PRIMARY KEY,
	data_id INT NOT NULL
);
ALTER TABLE bookbrainz.edition_group_import_header ADD FOREIGN KEY (import_id) REFERENCES bookbrainz.import (id);
ALTER TABLE bookbrainz.edition_group_import_header ADD FOREIGN KEY (data_id) REFERENCES bookbrainz.edition_group_data (id);

CREATE TABLE IF NOT EXISTS bookbrainz.publisher_import_header (
	import_id INT PRIMARY KEY,
	data_id INT NOT NULL
);
ALTER TABLE bookbrainz.publisher_import_header ADD FOREIGN KEY (import_id) REFERENCES bookbrainz.import (id);
ALTER TABLE bookbrainz.publisher_import_header ADD FOREIGN KEY (data_id) REFERENCES bookbrainz.publisher_data (id);

CREATE TABLE IF NOT EXISTS bookbrainz.work_import_header (
	import_id INT PRIMARY KEY,
	data_id INT NOT NULL
);
ALTER TABLE bookbrainz.work_import_header ADD FOREIGN KEY (import_id) REFERENCES bookbrainz.import (id);
ALTER TABLE bookbrainz.work_import_header ADD FOREIGN KEY (data_id) REFERENCES bookbrainz.work_data (id);

CREATE TABLE IF NOT EXISTS bookbrainz.discard_votes (
	import_id INT NOT NULL,
	editor_id INT NOT NULL,
	voted_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT timezone('UTC'::TEXT, now()),
	PRIMARY KEY (
		import_id,
		editor_id
	)
);
ALTER TABLE bookbrainz.discard_votes ADD FOREIGN KEY (import_id) REFERENCES bookbrainz.import (id);
ALTER TABLE bookbrainz.discard_votes ADD FOREIGN KEY (editor_id) REFERENCES bookbrainz.editor (id);

CREATE TABLE IF NOT EXISTS bookbrainz.origin_source (
	id SERIAL PRIMARY KEY,
	name TEXT NOT NULL CHECK (name <> '')
);

CREATE TABLE IF NOT EXISTS bookbrainz.link_import (
	import_id INT,
	origin_source_id INT NOT NULL,
	origin_id TEXT NOT NULL CHECK (origin_id <> ''),
	imported_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT timezone('UTC'::TEXT, now()),
	last_edited TIMESTAMP WITHOUT TIME ZONE,
	entity_id UUID DEFAULT NULL,
	import_metadata jsonb,
	PRIMARY KEY (
		origin_source_id,
		origin_id
	)
);
ALTER TABLE bookbrainz.link_import ADD FOREIGN KEY (entity_id) REFERENCES bookbrainz.entity (bbid);
ALTER TABLE bookbrainz.link_import ADD FOREIGN KEY (import_id) REFERENCES bookbrainz.import (id);
ALTER TABLE bookbrainz.link_import ADD FOREIGN KEY (origin_source_id) REFERENCES bookbrainz.origin_source (id);

CREATE TABLE bookbrainz.user_collection (
	id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),
	owner_id INT NOT NULL,
	name VARCHAR(80) NOT NULL CHECK (name <> ''),
	description TEXT NOT NULL DEFAULT '',
	entity_type bookbrainz.entity_type NOT NULL,
	public BOOLEAN NOT NULL DEFAULT FALSE,
	created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT timezone('UTC'::TEXT, now()),
	last_modified TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT timezone('UTC'::TEXT, now())
);
ALTER TABLE bookbrainz.user_collection ADD FOREIGN KEY (owner_id) REFERENCES bookbrainz.editor (id);

CREATE TABLE bookbrainz.user_collection_item (
	collection_id UUID,
	bbid UUID,
	added_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT timezone('UTC'::TEXT, now())
);
ALTER TABLE bookbrainz.user_collection_item ADD FOREIGN KEY (collection_id) REFERENCES bookbrainz.user_collection (id);
ALTER TABLE bookbrainz.user_collection_item ADD FOREIGN KEY (bbid) REFERENCES bookbrainz.entity (bbid);

CREATE TABLE bookbrainz.user_collection_collaborator (
	collection_id UUID,
	editor_id INT
);
ALTER TABLE bookbrainz.user_collection_collaborator ADD FOREIGN KEY (collection_id) REFERENCES bookbrainz.user_collection (id);
ALTER TABLE bookbrainz.user_collection_collaborator ADD FOREIGN KEY (editor_id) REFERENCES bookbrainz.editor (id);

-- Views --

CREATE VIEW bookbrainz.author AS
	SELECT
		e.bbid, cd.id AS data_id, cr.id AS revision_id, (cr.id = c.master_revision_id) AS master, cd.annotation_id, cd.disambiguation_id,
		als.default_alias_id, cd.begin_year, cd.begin_month, cd.begin_day, cd.begin_area_id,
		cd.end_year, cd.end_month, cd.end_day, cd.end_area_id, cd.ended, cd.area_id,
		cd.gender_id, cd.type_id, cd.alias_set_id, cd.identifier_set_id, cd.relationship_set_id, e.type
	FROM bookbrainz.author_revision cr
	LEFT JOIN bookbrainz.entity e ON e.bbid = cr.bbid
	LEFT JOIN bookbrainz.author_header c ON c.bbid = e.bbid
	LEFT JOIN bookbrainz.author_data cd ON cr.data_id = cd.id
	LEFT JOIN bookbrainz.alias_set als ON cd.alias_set_id = als.id
	WHERE e.type = 'Author';

CREATE VIEW bookbrainz.edition AS
	SELECT
		e.bbid, edd.id AS data_id, edr.id AS revision_id, (edr.id = ed.master_revision_id) AS master, edd.annotation_id, edd.disambiguation_id,
		als.default_alias_id, edd.edition_group_bbid, edd.author_credit_id, edd.width, edd.height,
		edd.depth, edd.weight, edd.pages, edd.format_id, edd.status_id,
		edd.alias_set_id, edd.identifier_set_id, edd.relationship_set_id, e.type,
		edd.language_set_id, edd.release_event_set_id, edd.publisher_set_id
	FROM bookbrainz.edition_revision edr
	LEFT JOIN bookbrainz.entity e ON e.bbid = edr.bbid
	LEFT JOIN bookbrainz.edition_header ed ON ed.bbid = e.bbid
	LEFT JOIN bookbrainz.edition_data edd ON edr.data_id = edd.id
	LEFT JOIN bookbrainz.alias_set als ON edd.alias_set_id = als.id
	WHERE e.type = 'Edition';

CREATE VIEW bookbrainz.work AS
	SELECT
		e.bbid, wd.id AS data_id, wr.id AS revision_id, (wr.id = w.master_revision_id) AS master, wd.annotation_id, wd.disambiguation_id,
		als.default_alias_id, wd.type_id, wd.alias_set_id, wd.identifier_set_id,
		wd.relationship_set_id, e.type, wd.language_set_id
	FROM bookbrainz.work_revision wr
	LEFT JOIN bookbrainz.entity e ON e.bbid = wr.bbid
	LEFT JOIN bookbrainz.work_header w ON w.bbid = e.bbid
	LEFT JOIN bookbrainz.work_data wd ON wr.data_id = wd.id
	LEFT JOIN bookbrainz.alias_set als ON wd.alias_set_id = als.id
	WHERE e.type = 'Work';

CREATE VIEW bookbrainz.publisher AS
	SELECT
		e.bbid, psd.id AS data_id, psr.id AS revision_id, (psr.id = ps.master_revision_id) AS master, psd.annotation_id, psd.disambiguation_id,
		als.default_alias_id, psd.begin_year, psd.begin_month, psd.begin_day,
		psd.end_year, psd.end_month, psd.end_day, psd.ended, psd.area_id,
		psd.type_id, psd.alias_set_id, psd.identifier_set_id, psd.relationship_set_id, e.type
	FROM bookbrainz.publisher_revision psr
	LEFT JOIN bookbrainz.entity e ON e.bbid = psr.bbid
	LEFT JOIN bookbrainz.publisher_header ps ON ps.bbid = e.bbid
	LEFT JOIN bookbrainz.publisher_data psd ON psr.data_id = psd.id
	LEFT JOIN bookbrainz.alias_set als ON psd.alias_set_id = als.id
	WHERE e.type = 'Publisher';

CREATE VIEW bookbrainz.edition_group AS
	SELECT
		e.bbid, pcd.id AS data_id, pcr.id AS revision_id, (pcr.id = pc.master_revision_id) AS master, pcd.annotation_id, pcd.disambiguation_id,
		als.default_alias_id, pcd.type_id, pcd.author_credit_id, pcd.alias_set_id, pcd.identifier_set_id,
		pcd.relationship_set_id, e.type
	FROM bookbrainz.edition_group_revision pcr
	LEFT JOIN bookbrainz.entity e ON e.bbid = pcr.bbid
	LEFT JOIN bookbrainz.edition_group_header pc ON pc.bbid = e.bbid
	LEFT JOIN bookbrainz.edition_group_data pcd ON pcr.data_id = pcd.id
	LEFT JOIN bookbrainz.alias_set als ON pcd.alias_set_id = als.id
	WHERE e.type = 'EditionGroup';

CREATE VIEW bookbrainz.author_import AS
	SELECT
		import.id AS import_id,
		author_data.id as data_id,
		author_data.annotation_id,
		author_data.disambiguation_id,
		alias_set.default_alias_id,
		author_data.begin_year,
		author_data.begin_month,
		author_data.begin_day,
		author_data.end_year,
		author_data.end_month,
		author_data.end_day,
		author_data.begin_area_id,
		author_data.end_area_id,
		author_data.ended,
		author_data.area_id,
		author_data.gender_id,
		author_data.type_id,
		author_data.alias_set_id,
		author_data.identifier_set_id,
		import.type
	FROM bookbrainz.import import
	LEFT JOIN bookbrainz.author_import_header author_import_header ON import.id = author_import_header.import_id
	LEFT JOIN bookbrainz.author_data author_data ON author_import_header.data_id = author_data.id
	LEFT JOIN bookbrainz.alias_set alias_set ON author_data.alias_set_id = alias_set.id
	WHERE import.type = 'Author';


CREATE VIEW bookbrainz.edition_import AS
	SELECT
		import.id AS import_id,
		edition_data.id as data_id,
		edition_data.disambiguation_id,
		alias_set.default_alias_id,
		edition_data.width,
		edition_data.height,
		edition_data.depth,
		edition_data.weight,
		edition_data.pages,
		edition_data.format_id,
		edition_data.status_id,
		edition_data.alias_set_id,
		edition_data.identifier_set_id,
		import.type,
		edition_data.language_set_id,
		edition_data.release_event_set_id
	FROM bookbrainz.import import
	LEFT JOIN bookbrainz.edition_import_header edition_import_header ON import.id = edition_import_header.import_id
	LEFT JOIN bookbrainz.edition_data edition_data ON edition_import_header.data_id = edition_data.id
	LEFT JOIN bookbrainz.alias_set alias_set ON edition_data.alias_set_id = alias_set.id
	WHERE import.type = 'Edition';

CREATE VIEW bookbrainz.publisher_import AS
	SELECT
		import.id AS import_id,
		publisher_data.id as data_id,
		publisher_data.disambiguation_id,
		alias_set.default_alias_id,
		publisher_data.begin_year,
		publisher_data.begin_month,
		publisher_data.begin_day,
		publisher_data.end_year,
		publisher_data.end_month,
		publisher_data.end_day,
		publisher_data.ended,
		publisher_data.area_id,
		publisher_data.type_id,
		publisher_data.alias_set_id,
		publisher_data.identifier_set_id,
		import.type
	FROM
		bookbrainz.import import
		LEFT JOIN bookbrainz.publisher_import_header publisher_import_header ON import.id = publisher_import_header.import_id
		LEFT JOIN bookbrainz.publisher_data publisher_data ON publisher_import_header.data_id = publisher_data.id
		LEFT JOIN bookbrainz.alias_set alias_set ON publisher_data.alias_set_id = alias_set.id
		WHERE import.type = 'Publisher';

CREATE VIEW bookbrainz.edition_group_import AS
	SELECT
		import.id AS import_id,
		edition_group_data.id as data_id,
		edition_group_data.disambiguation_id,
		alias_set.default_alias_id,
		edition_group_data.type_id,
		edition_group_data.alias_set_id,
		edition_group_data.identifier_set_id,
		import.type
	FROM bookbrainz.import import
	LEFT JOIN bookbrainz.edition_group_import_header edition_group_import_header ON import.id = edition_group_import_header.import_id
	LEFT JOIN bookbrainz.edition_group_data edition_group_data ON edition_group_import_header.data_id = edition_group_data.id
	LEFT JOIN bookbrainz.alias_set alias_set ON edition_group_data.alias_set_id = alias_set.id
	WHERE import.type = 'EditionGroup';

CREATE VIEW bookbrainz.work_import AS
	SELECT
		import.id as import_id,
		work_data.id AS data_id,
		work_data.annotation_id,
		work_data.disambiguation_id,
		alias_set.default_alias_id,
		work_data.type_id,
		work_data.alias_set_id,
		work_data.identifier_set_id,
		import.type,
		work_data.language_set_id
	FROM bookbrainz.import import
	LEFT JOIN bookbrainz.work_import_header work_import_header ON import.id = work_import_header.import_id
	LEFT JOIN bookbrainz.work_data work_data ON work_import_header.data_id = work_data.id
	LEFT JOIN bookbrainz.alias_set alias_set ON work_data.alias_set_id = alias_set.id
	WHERE import.type = 'Work';

COMMIT;
