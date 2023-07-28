/*
 * Copyright (C) 2023 Shivam Awasthi
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
import {Button, Card, Col, Form, Modal, Row} from 'react-bootstrap';
import React, {ChangeEvent, FormEvent, useCallback, useState} from 'react';
import {RelationshipTypeDataT, RelationshipTypeEditorPropsT, defaultRelationshipTypeData, entityTypeOptions, renderSelectedParent} from './typeUtils';
import {faPencilAlt, faPlus, faTimes} from '@fortawesome/free-solid-svg-icons';
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome';
import ReactSelect from 'react-select';


function RelationshipTypeEditor({relationshipTypeData, parentTypes}: RelationshipTypeEditorPropsT) {
	const [formData, setFormData] = useState<RelationshipTypeDataT>(relationshipTypeData);

	// State for the ParentType modal
	const [showModal, setShowModal] = useState<boolean>(false);
	const [selectedParentType, setSelectedParentType] = useState<number | null>(formData.parentId);
	const [childOrder, setChildOrder] = useState<number>(formData.childOrder);

	// Callback function for opening the modal
	const handleAddParent = useCallback(() => {
		setShowModal(true);
	}, []);

	// Callback function for closing the modal, the state of the modal should alse be reset
	const handleModalClose = useCallback(() => {
		setSelectedParentType(null);
		setChildOrder(0);
		setShowModal(false);
	}, []);

	// Function to handle parent type selection in ParentType modal
	const handleParentTypeChange = useCallback((selectedOption) => {
		if (selectedOption) {
			setSelectedParentType(selectedOption.id);
		}
		else {
			setSelectedParentType(null);
		}
	}, [selectedParentType]);

	// Function to handle child order input in ParentType modal
	const handleChildOrderChange = useCallback((event: ChangeEvent<HTMLInputElement>) => {
		const value = parseInt(event.target.value, 10);
		setChildOrder(isNaN(value) ? 0 : value);
	}, [formData, childOrder]);

	// Function to handle parent removal using useCallback
	const handleRemoveParent = useCallback(() => {
		setFormData((prevFormData) => ({
			...prevFormData,
			childOrder: 0, parentId: null
		}));
		setChildOrder(0);
		setSelectedParentType(null);
	}, [formData]);

	const handleEditParent = useCallback(() => {
		setShowModal(true);
	}, []);

	// Function to handle parent type and child order edit submission
	const handleModalSubmit = useCallback(() => {
		if (selectedParentType !== null) {
			setFormData({
				...formData,
				childOrder, parentId: selectedParentType
			});
			setShowModal(false);
		}
	}, [formData, childOrder, selectedParentType]);

	const handleInputChange = useCallback((event: ChangeEvent<HTMLInputElement>) => {
		  const {name, value} = event.target;
		  setFormData((prevFormData) => ({
			...prevFormData,
			[name]: value
		  }));
	}, [formData]);

	const handleDeprecatedChange = useCallback((event: ChangeEvent<HTMLInputElement>) => {
		const {value} = event.target;
		setFormData((prevFormData) => ({
			...prevFormData,
			deprecated: value === 'true'
		}));
	}, [formData]);

	const getEntityTypeLabel = useCallback(option => option.name, []);

	const getEntityTypeValue = useCallback(option => option.name, []);

	const getParentTypeValue = useCallback(option => option.id, []);

	// Callback function to format the option label to include both forwardStatement and reverseStatement
	const formatParentTypeOptionLabel = useCallback(option => (
		<div className="small">
			<div>{option.sourceEntityType}&nbsp;{option.linkPhrase}&nbsp;{option.targetEntityType}</div>
			<div>{option.targetEntityType}&nbsp;{option.reverseLinkPhrase}&nbsp;{option.sourceEntityType}</div>
		</div>
	), []);

	const handleSourceEntityTypeChange = useCallback((selectedOption) => {
		if (selectedOption) {
			setFormData({...formData, sourceEntityType: selectedOption.name});
		}
		else {
			setFormData({...formData, sourceEntityType: null});
		}
	}, [formData]);

	const handleTargetEntityTypeChange = useCallback((selectedOption) => {
		if (selectedOption) {
			setFormData({...formData, targetEntityType: selectedOption.name});
		}
		else {
			setFormData({...formData, targetEntityType: null});
		}
	}, [formData]);

	const handleSubmit = useCallback((event: FormEvent<HTMLFormElement>) => {
		  event.preventDefault();
		//   console.log(formData);
	}, [formData]);

	const lgCol = {offset: 3, span: 6};

	return (
		<form onSubmit={handleSubmit}>
			<Card>
				<Card.Header as="h4">
					Add Relationship Type
				</Card.Header>
				<Card.Body>
					<Row>
						<Col lg={lgCol}>
							<Form.Group>
								<Form.Label>Label</Form.Label>
								<Form.Control
									required
									name="label"
									type="text"
									value={formData.label}
									onChange={handleInputChange}
								/>
							</Form.Group>
						</Col>
					</Row>
					<Row>
						<Col lg={lgCol}>
							<Form.Group>
								<Form.Label>Description</Form.Label>
								<Form.Control
									required
									name="description"
									type="text"
									value={formData.description}
									onChange={handleInputChange}
								/>
							</Form.Group>
						</Col>
					</Row>
					<Row>
						<Col lg={lgCol}>
							<Form.Group>
								<Form.Label>Link Phrase</Form.Label>
								<Form.Control
									required
									name="linkPhrase"
									type="text"
									value={formData.linkPhrase}
									onChange={handleInputChange}
								/>
							</Form.Group>
						</Col>
					</Row>
					<Row>
						<Col lg={lgCol}>
							<Form.Group>
								<Form.Label>Reverse Link Phrase</Form.Label>
								<Form.Control
									required
									name="reverseLinkPhrase"
									type="text"
									value={formData.reverseLinkPhrase}
									onChange={handleInputChange}
								/>
							</Form.Group>
						</Col>
					</Row>
					<Row>
						<Col lg={lgCol}>
							<Form.Group>
								<Form.Label>Source Entity Type</Form.Label>
								<ReactSelect
									classNamePrefix="react-select"
									defaultValue={entityTypeOptions.filter((option) => option.name === relationshipTypeData.sourceEntityType)}
									getOptionLabel={getEntityTypeLabel}
									getOptionValue={getEntityTypeValue}
									instanceId="sourceEntityType"
									options={entityTypeOptions}
									placeholder="Select Source Entity Type"
									onChange={handleSourceEntityTypeChange}
								/>
							</Form.Group>
						</Col>
					</Row>
					<Row>
						<Col lg={lgCol}>
							<Form.Group>
								<Form.Label>Target Entity Type</Form.Label>
								<ReactSelect
									classNamePrefix="react-select"
									defaultValue={entityTypeOptions.filter((option) => option.name === relationshipTypeData.targetEntityType)}
									getOptionLabel={getEntityTypeLabel}
									getOptionValue={getEntityTypeValue}
									instanceId="targetEntityType"
									options={entityTypeOptions}
									placeholder="Select Target Entity Type"
									onChange={handleTargetEntityTypeChange}
								/>
							</Form.Group>
						</Col>
					</Row>
					<Row>
						<Col lg={lgCol}>
							<Form.Group>
								<Form.Label>Parent Relationship</Form.Label>
								{!formData.parentId ? (
									<Row className="margin-top-1">
										<Col
											className="text-center"
										>
											<Button
												variant="success"
												onClick={handleAddParent}
											>
												<FontAwesomeIcon icon={faPlus}/>
												<span>&nbsp;Add Parent Relationship</span>
											</Button>
										</Col>
									</Row>
								) : (
									<Row className="margin-top-d5">
										<Col className="text-center">
											{formData.parentId && renderSelectedParent(formData.parentId, formData.childOrder, parentTypes)}
											<div className="btn-group d-flex margin-top-1" role="group">
												<Button
													className="w-100"
													href="#"
													role="button"
													variant="warning"
													onClick={handleEditParent}
												>
													<FontAwesomeIcon icon={faPencilAlt}/>
													<span>&nbsp;Edit</span>
												</Button>
												<Button
													className="w-100"
													href="#"
													role="button"
													variant="danger"
													onClick={handleRemoveParent}
												>
													<FontAwesomeIcon icon={faTimes}/>
													<span>&nbsp;Remove</span>
												</Button>
											</div>
										</Col>
									</Row>
								)}
							</Form.Group>
						</Col>
					</Row>

					<Row>
						<Col lg={lgCol}>
							<Form.Group>
								<Form.Label>Deprecated:</Form.Label>
								<Form.Control
									required
									as="select"
									name="deprecated"
									value={formData.deprecated.toString()}
									onChange={handleDeprecatedChange}
								>
									<option value="false">No</option>
									<option value="true">Yes</option>
								</Form.Control>
							</Form.Group>
						</Col>
					</Row>
					<Row>
						<Col className="text-center margin-top-d5" lg={lgCol}>
							<Button type="submit">Submit</Button>
						</Col>
					</Row>
					{/* Modal for selecting parent type */}
					<Modal show={showModal} onHide={handleModalClose}>
						<Modal.Header closeButton>
							<Modal.Title>{formData.parentId ? 'Edit Parent' : 'Add a Parent'}</Modal.Title>
						</Modal.Header>
						<Modal.Body>
							<Form.Group>
								<Form.Label>Parent Type:</Form.Label>
								<ReactSelect
									required
									classNamePrefix="react-select"
									formatOptionLabel={formatParentTypeOptionLabel}
									getOptionValue={getParentTypeValue}
									instanceId="parentType"
									options={parentTypes}
									value={parentTypes.find((option) => option.id === selectedParentType)}
									onChange={handleParentTypeChange}
								/>
							</Form.Group>
							<Form.Group >
								<Form.Label>Child Order:</Form.Label>
								<Form.Control
									required
									min={0}
									name="childOrder"
									type="number"
									value={childOrder}
									onChange={handleChildOrderChange}
								/>
							</Form.Group>
						</Modal.Body>
						<Modal.Footer>
							<Button variant="secondary" onClick={handleModalClose}>
								Close
							</Button>
							<Button variant="primary" onClick={handleModalSubmit}>
								{formData.parentId ? 'Save Changes' : 'Submit'}
							</Button>
						</Modal.Footer>
					</Modal>
				</Card.Body>
			</Card>
		</form>
	);
}

RelationshipTypeEditor.defaultProps = {
	relationshipTypeData: defaultRelationshipTypeData
};

export default RelationshipTypeEditor;
