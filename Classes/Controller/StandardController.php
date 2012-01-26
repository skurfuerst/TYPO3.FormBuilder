<?php
namespace TYPO3\FormBuilder\Controller;

/*                                                                        *
 * This script belongs to the FLOW3 package "TYPO3.FormBuilder".          *
 *                                                                        *
 *                                                                        */

use TYPO3\FLOW3\Annotations as FLOW3;

/**
 * Standard controller for the TYPO3.FormBuilder package
 *
 * @FLOW3\Scope("singleton")
 */
class StandardController extends \TYPO3\FLOW3\MVC\Controller\ActionController {

	/**
	 * Displays the example form
	 *
	 * @return void
	 */
	public function indexAction() {
	}

	/**
	 * @param array $formDefinition
	 * @param integer $currentPageIndex
	 */
	public function renderformpageAction($formDefinition, $currentPageIndex) {
		$formFactory = new \TYPO3\FormBuilder\FormBuilderFactory();
		$formDefinition = $formFactory->build($formDefinition, 'Default');
		$formDefinition->setRenderingOption('previewMode', TRUE);
		$form = $formDefinition->bind($this->request);
		$form->overrideCurrentPage($currentPageIndex);
		return $form->render();
	}
}
?>