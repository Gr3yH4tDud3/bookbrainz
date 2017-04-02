/*
 * Copyright (C) 2015       Ben Ockmore
 *               2015-2016  Sean Burke
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

'use strict';

const React = require('react');
const ReactDOMServer = require('react-dom/server');
const express = require('express');
const _ = require('lodash');

const auth = require('../../helpers/auth');
const utils = require('../../helpers/utils');

const entityRoutes = require('./entity');

/* Middleware loader functions. */
const loadEntityRelationships =
	require('../../helpers/middleware').loadEntityRelationships;
const loadIdentifierTypes =
	require('../../helpers/middleware').loadIdentifierTypes;
const loadLanguages = require('../../helpers/middleware').loadLanguages;
const loadPublisherTypes =
	require('../../helpers/middleware').loadPublisherTypes;
const makeEntityLoader = require('../../helpers/middleware').makeEntityLoader;

const EditForm = React.createFactory(
	require('../../../client/components/forms/publisher')
);

const router = express.Router();

/* If the route specifies a BBID, load the Publisher for it. */
router.param(
	'bbid',
	makeEntityLoader(
		'Publisher',
		['publisherType', 'area'],
		'Publisher not found'
	)
);

function _setPublisherTitle(res) {
	res.locals.title = utils.createEntityPageTitle(
		res.locals.entity,
		'Publisher',
		utils.template`Publisher “${'name'}”`
	);
}

router.get('/:bbid', loadEntityRelationships, (req, res, next) => {
	// Fetch editions
	const {Publisher} = req.app.locals.orm;
	const editionRelationsToFetch = [
		'defaultAlias', 'disambiguation', 'releaseEventSet.releaseEvents'
	];
	const editionsPromise =
		Publisher.forge({bbid: res.locals.entity.bbid})
			.editions({withRelated: editionRelationsToFetch});

	return editionsPromise
		.then((editions) => {
			res.locals.entity.editions = editions.toJSON();
			_setPublisherTitle(res);
			entityRoutes.displayEntity(req, res);
		})
		.catch(next);
});

router.get('/:bbid/delete', auth.isAuthenticated, (req, res) => {
	_setPublisherTitle(res);
	entityRoutes.displayDeleteEntity(req, res);
});

router.post('/:bbid/delete/handler', auth.isAuthenticatedForHandler,
	(req, res) => {
		const {orm} = req.app.locals;
		const {PublisherHeader, PublisherRevision} = orm;
		return entityRoutes.handleDelete(
			orm, req, res, PublisherHeader, PublisherRevision
		);
	}
);

router.get('/:bbid/revisions', (req, res, next) => {
	const {PublisherRevision} = req.app.locals.orm;
	_setPublisherTitle(res);
	entityRoutes.displayRevisions(req, res, next, PublisherRevision);
});

// Creation

router.get('/create', auth.isAuthenticated, loadIdentifierTypes, loadLanguages,
	loadPublisherTypes, (req, res) => {
		const props = {
			identifierTypes: res.locals.identifierTypes,
			languages: res.locals.languages,
			publisherTypes: res.locals.publisherTypes,
			submissionUrl: '/publisher/create/handler'
		};

		const markup = ReactDOMServer.renderToString(EditForm(props));

		res.render('entity/create/create-common', {
			heading: 'Create Publisher',
			markup,
			props,
			script: 'publisher',
			subheading: 'Add a new Publisher to BookBrainz',
			title: 'Add Publisher'
		});
	}
);

router.get('/:bbid/edit', auth.isAuthenticated, loadIdentifierTypes,
	loadPublisherTypes, loadLanguages, (req, res) => {
		const publisher = res.locals.entity;

		const props = {
			identifierTypes: res.locals.identifierTypes,
			languages: res.locals.languages,
			publisher,
			publisherTypes: res.locals.publisherTypes,
			submissionUrl: `/publisher/${publisher.bbid}/edit/handler`
		};

		const markup = ReactDOMServer.renderToString(EditForm(props));

		res.render('entity/create/create-common', {
			heading: 'Edit Publisher',
			markup,
			props,
			script: 'publisher',
			subheading: 'Edit an existing Publisher in BookBrainz',
			title: 'Edit Publisher'
		});
	}
);

const additionalPublisherProps = [
	'typeId', 'areaId', 'beginDate', 'endDate', 'ended'
];

router.post('/create/handler', auth.isAuthenticatedForHandler, (req, res) =>
	entityRoutes.createEntity(
		req, res, 'Publisher', _.pick(req.body, additionalPublisherProps)
	)
);

router.post('/:bbid/edit/handler', auth.isAuthenticatedForHandler, (req, res) =>
	entityRoutes.editEntity(
		req, res, 'Publisher', _.pick(req.body, additionalPublisherProps)
	)
);

module.exports = router;
