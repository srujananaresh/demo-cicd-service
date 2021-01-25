package com.vodafone.iot.gdsp.demoCICD.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class SampleService {
	
	/** The Constant LOGGER. */
	private static final Logger LOGGER = LoggerFactory.getLogger(SampleService.class);

	/** The Constant MYNAME. */
	private static final String MYNAME = SampleService.class.getSimpleName();
	
	public String helloWorld(){
		LOGGER.info("Invoking  [{}]", MYNAME);
		String response = "Hello World";
		return response;
	}

}
